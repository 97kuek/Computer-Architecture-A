#! /usr/bin/env python3

# Tiny Assembler for Tiny RISC-V simulator
#  (Computer Architecture A)
#  Keiji Kimura, 2020
#
# Usage:
#    ./tas file.s
#
# The above generates the file named "file.dat" 
# containing machine instructions for Tiny RISC-V

import re
import sys

# Type of RISCV Instruction Kind
INSN_TYPE = 0
R_TYPE = 1
I_TYPE = 2
IL_TYPE = 3
S_TYPE = 4
B_TYPE = 5
U_TYPE = 6
J_TYPE = 7

# Instruction Information Table
InsnTab = { # "mnemonic" : [ TYPE, op, func3, func7 ]
    "add" : [R_TYPE, 0x33, 0, 0],
    "sub" : [R_TYPE, 0x33, 0, 0x20],
    "and" : [R_TYPE, 0x33, 7, 0],
    "or"  : [R_TYPE, 0x33, 6, 0],
    "slt" : [R_TYPE, 0x33, 2, 0],
    "addi" : [I_TYPE, 0x13, 0, 0],
    "andi" : [I_TYPE, 0x13, 7, 0],
    "ori"  : [I_TYPE, 0x13, 6, 0],
    "slti" : [I_TYPE, 0x13, 2, 0],
    "lw"  : [IL_TYPE,0x03, 2, 0],
    "sw"  : [S_TYPE, 0x23, 2, 0],
    "beq" : [B_TYPE, 0x63, 0, 0],
    "lui" : [U_TYPE, 0x37, 0, 0],
    "j"   : [J_TYPE, 0x6f, 0, 0]}

# Register Name Table
RegTab = {
    "zero" : 0,
    "ra" :   1, "sp" :   2, "gp" : 3,  "tp" : 4,
    "t0" :   5, "t1" :   6, "t2" : 7,
    "fp" :   8, "s1" :   9,
    "a0" :  10, "a1" :  11, "a2" : 12, "a3" : 13,
    "a4" :  14, "a5" :  15, "a6" : 16, "a7" : 17,
    "s2" :  18, "s3" :  19, "s4" : 20, "s5" : 21,
    "s6" :  22, "s7" :  23, "s8" : 24, "s9" : 25,
    "s10" : 26, "s11" : 27,
    "t3" :  28, "t4" :  29, "t5" : 30, "t6" : 31}

# Base class of a line of assembly file
class TasLine:
    def __init__(self, line, pc, line_no):
        self.line = line
        self.pc = pc
        self.line_no = line_no
        self.fout = sys.stdout
        self.object = 0
        self.debug = False

    def set_fout(self, fout):
        self.fout = fout

    def set_debug(self, debug):
        self.debug = debug

    def next_pc(self):
        return self.pc+4

    def get_line(self):
        return self.line

    def get_pc(self):
        return self.pc

    def gen_code(self):
        return

    def out_object(self):
        print('%08x' % self.object, file = fout)

# Null line
class NulLine(TasLine):
    def __init__(self, line, pc, line_no):
        TasLine.__init__(self, line, pc, line_no)

    def next_pc(self):
        return self.pc

# types for get_imm
# given as "optype"
# default value is IMM_LO
IMM_LO = 0
IMM_HI = 1
IMM_BR = 2
IMM_ALL = 3

# get immediate and label value
def get_imm(imm, optype):
    retimm = 0
    if imm.find('hi(') == 0:
        optype = IMM_HI
        imm = re.sub(r'hi\(', '', imm)
        imm = re.sub(r'\).*$', '', imm)
    elif imm.find('lo(') == 0:
        optype = IMM_LO
        imm = re.sub(r'lo\(', '', imm)
        imm = re.sub(r'\).*$', '', imm)
    sign = 1
    if imm[0] == '-':
        sign = -1
        imm = imm.lstrip('-')
    if imm.isdigit():
        retimm = sign*int(imm)
    elif imm.find('0x') == 0:
        retimm = int(imm, 16) # currently ignore sign
    else:
        try:
            retimm = LabelTab[imm]
        except KeyError:
            print('Undefined Lable: %s' % imm, file = sys.stderr)
            sys.exit()
    if optype == IMM_LO:
        retimm = 0xfff & retimm
    elif optype == IMM_BR:
        retimm = 0x1fff & retimm
    elif optype == IMM_HI:
        retimm = (0xfffff000 & retimm) >> 12
    # else IMM_ALL
    return retimm

# Base class of a line of RISC-V instructions
class InsnLine(TasLine):
    def __init__(self, line, pc, line_no, tokens, iinfo):
        TasLine.__init__(self, line, pc, line_no)
        self.ope = tokens[0]
        self.op = tokens[1:4]
        self.iinfo = iinfo

    def get_reg(self, name):
        if name[0] == 'x':
            regnum = int(name[1:])
            if regnum < 0 or regnum > 31:
                print('Invalid Register Number: %d at line %d\n\t%s'
                      % (regnum, self.line_no, self.line),
                      file = sys.stderr)
                sys.exit()
        else:
            try:
                regnum = RegTab[name]
            except KeyError:
                print('Invalid Register Name: %s at line %d\n\t%s'
                      % (name, self.line_no, self.line),
                      file = sys.stderr)
                sys.exit()
        return regnum

    def check_num_operands(self, nop):
        ops = len(self.op)
        if ops < nop:
            print('Too few operands for %s at line %d. This requires %d operands.\n\t%s'
                  % (self.ope, self.line_no, nop, self.line), file = sys.stderr)
            sys.exit()
        if nop > nop:
            print('Too many operands for %s at line %d. This requires %d operands.\n\t%s'
                  % (self.ope, self.line_no, nop, self.line), file = sys.stderr)
            sys.exit()
        
# R-Format Instructions
#  op Rd, Rs1, Rs2
class RLine(InsnLine):
    def __init__(self, line, pc, line_no, tokens, iinfo):
        InsnLine.__init__(self, line, pc, line_no, tokens, iinfo)

    def gen_code(self):
        self.check_num_operands(3)
        for i in range(3):
            self.op[i] = self.get_reg(self.op[i])

        if self.debug:
            print('{%x,%x,%x}(%s), %d %d %d' % (self.iinfo[1],
                                                self.iinfo[2],
                                                self.iinfo[3],
                                                self.ope,
						self.op[0],
                                                self.op[1],
						self.op[2]))
        self.object = ((self.iinfo[3] << 25) + (self.op[2] << 20)
                       + (self.op[1] << 15) + (self.iinfo[2] << 12)
                       + (self.op[0] << 7) + self.iinfo[1])
        self.out_object()

# I-Format Instructions (Arithmetic and Logical)
#  op Rd, Rs1, Imm
class ILine(InsnLine):
    def __init__(self, line, pc, line_no, tokens, iinfo):
        InsnLine.__init__(self, line, pc, line_no, tokens, iinfo)

    def gen_code(self):
        self.check_num_operands(3)
        for i in range(2):
            self.op[i] = self.get_reg(self.op[i])
        self.op[2] = get_imm(self.op[2], IMM_LO)
        if self.debug:
            print('{%x,%x}(%s), %d %d %d' % (self.iinfo[1],
                                             self.iinfo[2],
                                             self.ope,
					     self.op[0],
                                             self.op[1],
					     self.op[2]))
        self.object = ((self.op[2] << 20) + (self.op[1] << 15)
                       + (self.iinfo[2] << 12) + (self.op[0] << 7)
                       + self.iinfo[1])
        self.out_object()

# B-Format Instructions (Branch)
#  op Rs1, Rs2, BranchTarget
class BLine(InsnLine):
    def __init__(self, line, pc, line_no, tokens, iinfo):
        InsnLine.__init__(self, line, pc, line_no, tokens, iinfo)

    def gen_code(self):
        self.check_num_operands(3)
        for i in range(2):
            self.op[i] = self.get_reg(self.op[i])
        boffset = get_imm(self.op[2], IMM_BR)-self.pc
        if self.debug:
            print('{%x,%x}(%s), %d %d %d' % (self.iinfo[1],
                                             self.iinfo[2],
                                             self.ope,
					     self.op[0],
                                             self.op[1],
					     boffset))
        self.object = (((boffset & 0x1000) << 19) + ((boffset & 0x7e0) << 20)
                       + (self.op[1] << 20) + (self.op[0] << 15)
                       + (self.iinfo[2] << 12) + ((boffset & 0x1e) << 7)
                       + ((boffset & 0x800) >> 4) + self.iinfo[1])
        self.out_object()

# I-Format (load) or S-Format Instructions (Memory Access)
#  op Rd, Off(Rs1) for a load instruction 
#    or op Rs1, Off(Rs1) for a store instruction
class ILSLine(InsnLine):
    def __init__(self, line, pc, line_no, tokens, iinfo):
        InsnLine.__init__(self, line, pc, line_no, tokens, iinfo)

    def gen_code(self):
        self.check_num_operands(2)
        self.op[0] = self.get_reg(self.op[0])
	# exploit offset
        offset = re.sub(r'\(.*\)', '', self.op[1])
        sign = 1
        if offset[0] == '-':
            sign = -1
            offset = offset.lstrip('-')
        if offset.isdigit():
            self.op.append((0xfff & (sign*int(offset))))
        else:
            print('Invalid offset expression at line %d.\n\t%s'
                  % (self.line_no, self.line),
                  file = sys.stderr)
            sys.exit()
	# exploit register
        reg = re.sub(r'^.*\(', '', self.op[1])
        reg = re.sub(r'\).*$', '', reg)
        reg = reg.strip()
        self.op[1] = self.get_reg(reg)
        if self.debug:
            print('{%x,%x}(%s), %d %d %d' % (self.iinfo[1],
                                             self.iinfo[2],
                                             self.ope,
					     self.op[0],
                                             self.op[1],
					     self.op[2]))
        if self.iinfo[0] == IL_TYPE:
            self.object = ((self.op[2] << 20) + (self.op[1] << 15)
                           + (self.iinfo[2] << 12) + (self.op[0] << 7)
                           + self.iinfo[1])
        elif self.iinfo[0] == S_TYPE:
            self.object = (((self.op[2] & 0xfe0) << 20) + (self.op[0] << 20)
                           + (self.op[1] << 15) + (self.iinfo[2] << 12)
                           + ((self.op[2] & 0x1f) << 7) + self.iinfo[1])
        else:
            print('Invalid memory instruction type: %s' % self.ope, file = sys.stderr)
        self.out_object()

# U-Format Instructions
#  op Rd, immediate(IMM_HI)
class ULine(InsnLine):
    def __init__(self, line, pc, line_no, tokens, iinfo):
        InsnLine.__init__(self, line, pc, line_no, tokens, iinfo)

    def gen_code(self):
        self.check_num_operands(2)
        self.op[0] = self.get_reg(self.op[0])
        self.op[1] = get_imm(self.op[1], IMM_ALL)
        if self.debug:
            print('%x(%s), %d %x' % (self.iinfo[1], self.ope,
                                     self.op[0], self.op[1]))
        self.object = (self.op[1] << 12) + (self.op[0] << 7) + self.iinfo[1]
        self.out_object()

# J-Format Instructions
#  op JumpTarget
# This is actually JAL instructin, but its destirnation registaer is currently fixed to the zero-register.
class JLine(InsnLine):
    def __init__(self, line, pc, line_no, tokens, iinfo):
        InsnLine.__init__(self, line, pc, line_no, tokens, iinfo)

    def gen_code(self):
        self.check_num_operands(1)
        self.op[0] = 0x001fffff & (get_imm(self.op[0], IMM_ALL)-self.pc)
        if self.debug:
            print('%x(%s), %x' % (self.iinfo[1], self.ope, self.op[0]))
        self.object = ((  (self.op[0] & 0x00100000) << 11)
                       +  (self.op[0] & 0x000ff000)
                       + ((self.op[0] & 0x00000800) << 9)
                       + ((self.op[0] & 0x000007fe) << 20)
                       + self.iinfo[1])
        self.out_object()
		

# Basic class of Pseudo Instructions
class PLine(TasLine):
    def __init__(self, line, pc, line_no):
        TasLine.__init__(self, line, pc, line_no)

# DW
#  .dw data
class DWLine(PLine):
    def __init__(self, line, pc, line_no, data):
        PLine.__init__(self, line, pc, line_no)
        self.object = data

    def gen_code(self):
        self.out_object()

# Factory function for line objects
def  newInsnLine(line, pc, ine_no, tokens):
    # check pseudo instructions
    if tokens[0] == '.org':
        adrs = get_imm(tokens[1], IMM_ALL)
        return NulLine(line, adrs, line_no)
    elif tokens[0] == '.dw':
        dwdata = get_imm(tokens[1], IMM_ALL)
        return DWLine(line, pc, line_no, dwdata)
    # check RISC-V instructions
    try:
        insn_info = InsnTab[tokens[0]]
    except KeyError:
        print('Invalid instruction: %s at line %d\n\t%s'
              % (tokens[0], line_no, line), file = sys.stderr)
        sys.exit()
    if insn_info[0] == R_TYPE:
        return RLine(line, pc, line_no, tokens, insn_info)
    elif insn_info[0] == I_TYPE:
        return ILine(line, pc, line_no, tokens, insn_info)
    elif insn_info[0] == B_TYPE:
        return BLine(line, pc, line_no, tokens, insn_info)
    elif insn_info[0] == IL_TYPE or insn_info[0] == S_TYPE:
        return ILSLine(line, pc, line_no, tokens, insn_info)
    elif insn_info[0] == U_TYPE:
        return ULine(line, pc, line_no, tokens, insn_info)
    elif insn_info[0] == J_TYPE:
        return JLine(line, pc, line_no, tokens, insn_info)
    else:
        return InsnLine(line, pc, line_no, tokens)

def  exploitLabel(line, pc):
    lmatch = re.match('^.*:', line)
    if lmatch:
        label = re.sub(':', '', lmatch.group())
        LabelTab[label] = pc
    return re.sub(r'^.*:\s*', '', line)

def  newTasLine(line, pc, line_no):
    nline = re.sub(';.*', '', line) # remove comment
    nline = re.sub(',', ' ', nline)  # remove comma
    nline = exploitLabel(nline, pc)
    if nline == '' :
        return NulLine(nline, pc, line_no)
    tokens = nline.split()
    rline = newInsnLine(nline, pc, line_no, tokens)
    return rline

# Initialization
LabelTab = {}
tas_pc = 0
line_no = 0
insn_list = []

DEBUG = False
file_in = ''

# Processing command line arguments
for arg in sys.argv[1:]:
    if arg[0] == '-':
        if arg == '-debug':
            DEBUG = True
        else:
            print('Unkown command line option.', file = sys.stderr)
            sys.exit()
    else:
        file_in = arg

if len(file_in) == 0:
    print('Source file name is not specified.', file = sys.stderr)
    sys.exit()
if file_in.rfind('.s') == -1:
    print('Illegal suffix in the source file name.', file = sys.stderr)
    sys.exit()

file_out = file_in.replace('.s', '.dat')


try:
    fin = open(file_in)
    fout = open(file_out, 'w')
except IOError as e:
    print(file_in, ':', e.strerror, file = sys.stderr)
    sys.exit()

# Pass1: exploiting labels and storing instruction information
for line in fin:
    line_no = line_no+1
    line = line.strip()
    # remove comments
    tas_line = newTasLine(line, tas_pc, line_no)
    tas_line.set_fout(fout)
    tas_line.set_debug(DEBUG)
    tas_pc = tas_line.next_pc()
    insn_list.append(tas_line)

if DEBUG:
    print(LabelTab)

# Pass2: generating code
for insn in insn_list:
    insn.gen_code()
    if DEBUG:
        print(insn.get_pc(), insn.get_line())
