# a99lint.py
#
# Reformats TMS9900 assembly (.a99) files to consistent formatting.
#
# Copyright (c) 2026 Troy Schrapel
#
# This code is licensed under the MIT license
#
# VS Code Keybinding:
# To run this linter with Ctrl+Shift+L:
# 1. Open Command Palette (Ctrl+Shift+P)
# 2. Type "Preferences: Open Keyboard Shortcuts (JSON)"
# 3. Add this keybinding:
#    {
#        "key": "ctrl+shift+l",
#        "command": "workbench.action.tasks.runTask",
#        "args": "Lint A99 File",
#        "when": "resourceExtname == .a99"
#    }
#

import re
import sys
from pathlib import Path

# Column positions (0-indexed)
COL_LABEL = 0
COL_PREPROC = 2
COL_OPCODE = 4
COL_ARGS = 12
COL_EQU_BSS = 20
COL_COMMENT = 40

# Keywords that define constants/variables (not opcodes)
DIRECTIVE_KEYWORDS = {'EQU', 'BSS'}

# All assembler directives and opcodes (for detection)
OPCODES = {
    # TMS9900 opcodes
    'A', 'AB', 'ABS', 'AI', 'ANDI', 'B', 'BL', 'BLWP', 'C', 'CB', 'CI',
    'CKOF', 'CKON', 'CLR', 'COC', 'CZC', 'DEC', 'DECT', 'DIV', 'IDLE',
    'INC', 'INCT', 'INV', 'JEQ', 'JGT', 'JH', 'JHE', 'JL', 'JLE', 'JLT',
    'JMP', 'JNC', 'JNE', 'JNO', 'JOC', 'JOP', 'LDCR', 'LI', 'LIMI',
    'LREX', 'LWPI', 'MOV', 'MOVB', 'MPY', 'NEG', 'ORI', 'RSET', 'RT',
    'RTWP', 'S', 'SB', 'SBO', 'SBZ', 'SETO', 'SLA', 'SOC', 'SOCB',
    'SRA', 'SRC', 'SRL', 'STCR', 'STST', 'STWP', 'SWPB', 'SZC', 'SZCB',
    'TB', 'X', 'XOP', 'XOR',
    # GPU-specific
    'CALL', 'RET', 'PUSH', 'POP',
    # Assembler directives
    'DATA', 'BYTE', 'TEXT', 'EVEN', 'DORG', 'AORG', 'END', 'DEF', 'REF',
    'EQU', 'BSS', 'COPY', 'TITL', 'PAGE', 'LIST', 'UNL',
    # Preprocessor directives
    '.DEFM', '.ENDM', '.IFDEF', '.IFNDEF', '.IFEQ', '.IFNE', '.IFGE', '.IFGT',
    '.IFLE', '.IFLT', '.ELSE', '.ENDIF', '.REPT', '.ENDR', '.PRINT', '.ERROR',
}


def parse_line(line):
    """Parse an assembly line into components: label, opcode, args, comment."""
    original = line.rstrip('\n\r')
    stripped = original.lstrip()

    # Empty line
    if not stripped:
        return {'type': 'blank', 'original': original}

    # Full-line comment
    if stripped.startswith(';') or stripped.startswith('*'):
        had_indent = len(original) > len(stripped)
        return {'type': 'comment', 'text': stripped, 'had_indent': had_indent}

    # Track if we're in a string to avoid splitting on ; inside strings
    result = {'type': 'code', 'label': None, 'opcode': None, 'args': None, 'comment': None}

    # Extract end-of-line comment (not inside quotes)
    code_part = ''
    comment_part = None
    in_string = False
    for i, ch in enumerate(stripped):
        if ch == '"':
            in_string = not in_string
        elif ch == ';' and not in_string:
            code_part = stripped[:i].rstrip()
            comment_part = stripped[i:]
            break
    else:
        code_part = stripped

    result['comment'] = comment_part

    if not code_part:
        # Line was just a comment
        return {'type': 'comment', 'text': comment_part, 'had_indent': len(original) > len(stripped)}

    # Check for label (starts at column 0 in original, or has colon)
    # Labels: start with letter/!/_, may end with :
    tokens = code_part.split()
    if not tokens:
        return result

    first = tokens[0]

    # Check if first token is a label
    # A label either:
    # 1. Ends with ':'
    # 2. Is at column 0 and is followed by EQU or BSS
    # 3. Is at column 0, starts with letter/!/_ and next token is an opcode

    is_label = False
    if first.endswith(':'):
        is_label = True
        result['label'] = first[:-1]  # Store without colon, we'll add it back
        tokens = tokens[1:]
    elif first.startswith('!'):
        # Local labels start with ! - always treat as label regardless of indentation
        is_label = True
        result['label'] = first
        tokens = tokens[1:]
    elif first.startswith('.'):
        # Preprocessor directives start with . - not a label, treat as opcode
        pass
    elif not original.startswith((' ', '\t')):
        # At column 0 - could be label if followed by opcode/EQU/BSS
        if len(tokens) > 1 and tokens[1].upper() in OPCODES:
            is_label = True
            result['label'] = first  # Store without colon
            tokens = tokens[1:]
        elif len(tokens) > 1 and tokens[1].upper() in DIRECTIVE_KEYWORDS:
            is_label = True
            result['label'] = first  # Store without colon
            tokens = tokens[1:]
        elif len(tokens) == 1 and first.upper() not in OPCODES:
            # Single token at column 0 that's not an opcode - it's a label
            is_label = True
            result['label'] = first
            tokens = []

    if not tokens:
        return result

    # Next token should be opcode
    result['opcode'] = tokens[0]

    # Rest is arguments (preserve original spacing within args for strings)
    if len(tokens) > 1:
        # Find where args start in code_part
        # Use (?<!\w) and (?!\w) instead of \b for opcodes that start with '.'
        opcode_escaped = re.escape(result['opcode'])
        opcode_match = re.search(r'(?<![.\w])' + opcode_escaped + r'(?!\w)', code_part, re.IGNORECASE)
        if opcode_match:
            args_start = opcode_match.end()
            result['args'] = code_part[args_start:].strip()

    return result


def normalize_comma_spacing(args):
    """Ensure single space after commas, no space before."""
    if not args:
        return args

    # Handle strings carefully - don't modify commas inside strings
    result = []
    in_string = False
    i = 0
    while i < len(args):
        ch = args[i]
        if ch == '"':
            in_string = not in_string
            result.append(ch)
            i += 1
        elif ch == ',' and not in_string:
            result.append(',')
            # Skip any whitespace after comma
            i += 1
            while i < len(args) and args[i] in (' ', '\t'):
                i += 1
            # Add single space (unless end of string)
            if i < len(args):
                result.append(' ')
        else:
            result.append(ch)
            i += 1

    return ''.join(result)


def format_line(parsed):
    """Format a parsed line according to the style rules."""
    if parsed['type'] == 'blank':
        return ''

    if parsed['type'] == 'comment':
        if parsed['had_indent']:
            return ' ' * COL_OPCODE + parsed['text']
        else:
            return parsed['text']

    # Code line
    parts = []

    label = parsed.get('label')
    opcode = parsed.get('opcode')
    args = parsed.get('args')
    comment = parsed.get('comment')

    # Normalize comma spacing in args
    if args:
        args = normalize_comma_spacing(args)

    # Ensure label has colon
    if label and not label.endswith(':'):
        label = label + ':'

    # Label-only line
    if label and not opcode:
        return label

    # EQU/BSS lines: label at 0 (no colon for these), keyword at COL_EQU_BSS, value after
    if opcode and opcode.upper() in DIRECTIVE_KEYWORDS:
        line = ''
        if label:
            line = label.rstrip(':')  # EQU/BSS labels don't use colons
        # Ensure at least one space between label and opcode
        if len(line) < COL_EQU_BSS:
            line = line.ljust(COL_EQU_BSS)
        else:
            line += ' '
        line += opcode.upper()
        if args:
            line += ' ' + args
        if comment:
            if len(line) < COL_COMMENT:
                line = line.ljust(COL_COMMENT)
            else:
                line += ' '
            line += comment
        return line

    # Preprocessor directives: start at COL_PREPROC, args immediately after (one space)
    if opcode and opcode.startswith('.'):
        line = ' ' * COL_PREPROC + opcode.lower()
        if args:
            line += ' ' + args
        if comment:
            if len(line) < COL_COMMENT:
                line = line.ljust(COL_COMMENT)
            else:
                line += ' '
            line += comment
        return line

    # Regular opcode line
    line = ''
    if label:
        # Split label to its own line - return two lines
        label_line = label
        opcode_line = format_opcode_line(opcode, args, comment)
        return label_line + '\n' + opcode_line
    else:
        return format_opcode_line(opcode, args, comment)


def format_opcode_line(opcode, args, comment):
    """Format an opcode line (no label)."""
    line = ' ' * COL_OPCODE
    if opcode:
        line += opcode.upper()
    if args:
        # Pad to args column
        if len(line) < COL_ARGS:
            line = line.ljust(COL_ARGS)
        else:
            line += ' '
        line += args
    if comment:
        if len(line) < COL_COMMENT:
            line = line.ljust(COL_COMMENT)
        else:
            line += ' '
        line += comment
    return line


def lint_file(input_path, output_path=None, in_place=False):
    """Lint an .a99 file."""
    input_path = Path(input_path)

    if not input_path.exists():
        print(f"Error: File not found: {input_path}")
        return False

    with open(input_path, 'r') as f:
        lines = f.readlines()

    output_lines = []
    prev_blank = False

    for line in lines:
        parsed = parse_line(line)
        formatted = format_line(parsed)

        # Handle blank line collapsing
        if parsed['type'] == 'blank':
            if prev_blank:
                continue  # Skip consecutive blank lines
            prev_blank = True
        else:
            prev_blank = False

        # formatted might contain newlines (for split label+opcode)
        output_lines.append(formatted)

    output_text = '\n'.join(output_lines)

    # Ensure file ends with newline
    if output_text and not output_text.endswith('\n'):
        output_text += '\n'

    if in_place:
        output_path = input_path
    elif output_path is None:
        # Print to stdout
        print(output_text, end='')
        return True

    with open(output_path, 'w') as f:
        f.write(output_text)

    print(f"Formatted: {input_path}" + (" (in-place)" if in_place else f" -> {output_path}"))
    return True


def main():
    if len(sys.argv) < 2:
        print("Usage: python a99lint.py <input.a99> [-i] [output.a99]")
        print("  -i    Edit file in-place")
        print("  Without -i or output, prints to stdout")
        sys.exit(1)

    input_file = sys.argv[1]
    in_place = '-i' in sys.argv

    # Find output file if specified (not -i flag)
    output_file = None
    for arg in sys.argv[2:]:
        if arg != '-i':
            output_file = arg
            break

    lint_file(input_file, output_file, in_place)


if __name__ == '__main__':
    main()
