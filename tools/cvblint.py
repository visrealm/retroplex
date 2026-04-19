# cvblint.py
#
# Reformats CVBasic (.bas) files to consistent formatting with proper indentation.
#
# Copyright (c) 2026 Troy Schrapel
#
# This code is licensed under the MIT license
#
# VS Code Keybinding:
# To run this linter with Ctrl+Shift+V (V for CVBasic):
# 1. Open Command Palette (Ctrl+Shift+P)
# 2. Type "Preferences: Open Keyboard Shortcuts (JSON)"
# 3. Add this keybinding:
#    {
#        "key": "ctrl+shift+l",
#        "command": "workbench.action.tasks.runTask",
#        "args": "Lint CVBasic File",
#        "when": "resourceExtname == .bas"
#    }
#

import re
import sys
from pathlib import Path

# Indentation settings
INDENT_SIZE = 2

# Keywords that increase indentation AFTER the line
INDENT_INCREASE_AFTER = {
    'WHILE', 'FOR', 'DO', 'SELECT CASE', 'PROCEDURE', '#IF'
}

# Keywords that increase indentation and also decrease BEFORE (like ELSE, ELSEIF, CASE)
INDENT_MIDDLE = {
    'ELSE', 'ELSEIF', 'CASE ELSE', '#ELIF', '#ELSE'
}

# Keywords that decrease indentation BEFORE the line
INDENT_DECREASE_BEFORE = {
    'WEND', 'NEXT', 'LOOP', 'END SELECT', 'END IF', '#ENDIF'
}

# Keywords for multi-line IF detection
IF_THEN_PATTERN = re.compile(r'\bIF\b.*\bTHEN\s*$', re.IGNORECASE)
ELSEIF_THEN_PATTERN = re.compile(r'\bELSEIF\b.*\bTHEN\s*$', re.IGNORECASE)


def is_comment_line(line):
    """Check if line is a full-line comment."""
    stripped = line.lstrip()
    return stripped.startswith("'") or stripped.upper().startswith("REM ")


def is_blank_line(line):
    """Check if line is blank."""
    return not line.strip()


def has_label(line):
    """Check if line has a label at the start."""
    stripped = line.lstrip()
    if not stripped or is_comment_line(line):
        return False
    # Check for label: pattern (word followed by colon)
    match = re.match(r'^([a-zA-Z_#\.][a-zA-Z0-9_]*)\s*:', stripped)
    return match is not None


def get_label(line):
    """Extract label from line if present."""
    stripped = line.lstrip()
    match = re.match(r'^([a-zA-Z_#\.][a-zA-Z0-9_]*)\s*:\s*(.*)', stripped)
    if match:
        return match.group(1) + ':', match.group(2)
    return None, line


def remove_inline_comment(line):
    """Remove inline comment from line, preserving string contents."""
    in_string = False
    for i, ch in enumerate(line):
        if ch == '"':
            in_string = not in_string
        elif ch == "'" and not in_string:
            return line[:i].rstrip(), line[i:]
    return line, None


def normalize_spacing(code):
    """Normalize spacing in code: spaces after commas and around operators."""
    if not code.strip():
        return code

    # Extract and replace string literals with placeholders
    strings = []
    in_string = False
    result = []
    current_string = []

    for ch in code:
        if ch == '"':
            if in_string:
                # End of string
                current_string.append(ch)
                placeholder = f"__STR{len(strings)}__"
                strings.append(''.join(current_string))
                result.append(placeholder)
                current_string = []
                in_string = False
            else:
                # Start of string
                in_string = True
                current_string.append(ch)
        elif in_string:
            current_string.append(ch)
        else:
            result.append(ch)

    code_without_strings = ''.join(result)

    # Add space after commas (if not already present)
    code_without_strings = re.sub(r',(?!\s)', ', ', code_without_strings)

    # Add spaces around operators (but be careful with special cases)
    # Binary operators: =, +, -, *, /, >, <, >=, <=, <>
    operators = [
        (r'>=', ' >= '),  # Handle multi-char operators first
        (r'<=', ' <= '),
        (r'<>', ' <> '),
        (r'([^<>])=([^=])', r'\1 = \2'),  # = but not part of >=, <=, <>
        (r'\+', ' + '),
        (r'\*', ' * '),
        (r'([^/])/([^/])', r'\1 / \2'),  # / but not //
        (r'([^<>=])>([^=])', r'\1 > \2'),  # > but not part of >=
        (r'([^<>=])<([^>=])', r'\1 < \2'),  # < but not part of <=, <>
    ]

    for pattern, replacement in operators:
        code_without_strings = re.sub(pattern, replacement, code_without_strings)

    # Handle minus operator carefully (distinguish unary vs binary)
    # Unary minus: after =, (, comma, or operators; Binary minus: between operands
    # First add spaces around binary minus
    code_without_strings = re.sub(r'([a-zA-Z0-9_#)\]])(-)', r'\1 - ', code_without_strings)
    code_without_strings = re.sub(r'(-)([a-zA-Z0-9_#(])', r' - \2', code_without_strings)

    # Clean up unary minus: remove extra space between operator/delimiter and minus sign
    # Keep one space after = and comma, but remove space between minus and number
    # Pattern: "= - 5" -> "= -5", "( - 5)" -> "(-5)", ", - 5" -> ", -5"
    code_without_strings = re.sub(r'=\s+-\s+', '= -', code_without_strings)
    code_without_strings = re.sub(r'\(\s*-\s+', '(-', code_without_strings)
    code_without_strings = re.sub(r',\s+-\s+', ', -', code_without_strings)
    code_without_strings = re.sub(r'\+\s+-\s+', '+ -', code_without_strings)
    code_without_strings = re.sub(r'\*\s+-\s+', '* -', code_without_strings)
    code_without_strings = re.sub(r'/\s+-\s+', '/ -', code_without_strings)
    code_without_strings = re.sub(r'(<|>)\s+-\s+', r'\1 -', code_without_strings)

    # Add spaces around word operators (AND, OR, MOD, etc.)
    word_operators = ['AND', 'OR', 'MOD', 'XOR']
    for op in word_operators:
        code_without_strings = re.sub(
            r'\b' + op + r'\b',
            f' {op} ',
            code_without_strings,
            flags=re.IGNORECASE
        )

    # Clean up multiple spaces
    code_without_strings = re.sub(r'  +', ' ', code_without_strings)

    # Fix special case: <digit> operator (bit/byte selection) - remove spaces
    code_without_strings = re.sub(r'<\s*(\d+)\s*>', r'<\1>', code_without_strings)

    # Clean up spaces before opening parenthesis in function calls and array subscripts
    # But keep space after keywords like IF, WHILE, FOR
    keywords_needing_space = r'\b(IF|WHILE|FOR|ELSEIF|UNTIL|PRINT|DATA|DEFINE|VARPTR|BANKSEL)\b'
    # First mark keywords with a special marker
    code_without_strings = re.sub(
        keywords_needing_space + r'\s+\(',
        lambda m: m.group(1) + '__KEEPSPACE__(',
        code_without_strings,
        flags=re.IGNORECASE
    )
    # Remove spaces before parentheses
    code_without_strings = re.sub(r'\s+\(', '(', code_without_strings)
    # Restore spaces after keywords
    code_without_strings = code_without_strings.replace('__KEEPSPACE__(', ' (')

    # Clean up spaces around parentheses (no space after opening or before closing)
    code_without_strings = re.sub(r'\(\s+', '(', code_without_strings)
    code_without_strings = re.sub(r'\s+\)', ')', code_without_strings)

    # Restore string literals
    for i, string in enumerate(strings):
        placeholder = f"__STR{i}__"
        code_without_strings = code_without_strings.replace(placeholder, string)

    return code_without_strings


def align_const_statement(code):
    """Align CONST statements with = at column 32 or next multiple of 8."""
    stripped = code.strip()
    stripped_upper = stripped.upper()

    # Check if this is a CONST statement
    if not stripped_upper.startswith('CONST '):
        return code

    # Parse: CONST name = value
    match = re.match(r'(CONST\s+)(\S+)\s*=\s*(.+)', stripped, re.IGNORECASE)
    if not match:
        return code

    const_keyword = match.group(1)
    const_name = match.group(2)
    value = match.group(3)

    # Calculate current length of "CONST name"
    prefix_len = len(const_keyword) + len(const_name)

    # Target column for = is 32, or next multiple of 8 if needed
    target_col = 32
    while target_col <= prefix_len:
        target_col += 8

    # Calculate spaces needed before =
    spaces_needed = target_col - prefix_len

    # Format: "CONST name<spaces>= value"
    return const_keyword + const_name + ' ' * spaces_needed + '= ' + value


def get_statement_keywords(line):
    """Extract the main keywords from a statement (without comments)."""
    code_part, comment = remove_inline_comment(line)
    code_upper = code_part.upper().strip()

    keywords = []

    # Check for preprocessor directives (case-insensitive, with #)
    if re.match(r'^\s*#IF\b', code_upper):
        keywords.append('#IF')
    if re.match(r'^\s*#ELIF\b', code_upper):
        keywords.append('#ELIF')
    if re.match(r'^\s*#ELSE\b', code_upper):
        keywords.append('#ELSE')
    if re.match(r'^\s*#ENDIF\b', code_upper):
        keywords.append('#ENDIF')

    # Check for control structure keywords
    if re.match(r'^\s*WHILE\b', code_upper):
        keywords.append('WHILE')
    if re.match(r'^\s*WEND\b', code_upper):
        keywords.append('WEND')
    if re.match(r'^\s*FOR\b', code_upper):
        keywords.append('FOR')
    if re.match(r'^\s*NEXT\b', code_upper):
        keywords.append('NEXT')
    if re.match(r'^\s*DO\b', code_upper):
        keywords.append('DO')
    if re.match(r'^\s*LOOP\b', code_upper):
        keywords.append('LOOP')
    if re.match(r'^\s*SELECT\s+CASE\b', code_upper):
        keywords.append('SELECT CASE')
    if re.match(r'^\s*END\s+SELECT\b', code_upper):
        keywords.append('END SELECT')
    if re.match(r'^\s*CASE\s+ELSE\b', code_upper):
        keywords.append('CASE ELSE')
    elif re.match(r'^\s*CASE\b', code_upper):
        keywords.append('CASE')
    if re.match(r'^\s*END\s+IF\b', code_upper):
        keywords.append('END IF')
    if re.match(r'^\s*ELSE\b', code_upper):
        keywords.append('ELSE')
    if re.match(r'^\s*ELSEIF\b', code_upper):
        keywords.append('ELSEIF')
    if re.match(r'^\s*PROCEDURE\b', code_upper):
        keywords.append('PROCEDURE')

    # Check for END (procedure end)
    # Only treat END as procedure end if no other keywords match
    if not keywords and re.match(r'^\s*END\s*$', code_upper):
        keywords.append('END')

    # Multi-line IF detection
    if IF_THEN_PATTERN.search(code_part):
        keywords.append('IF_MULTILINE')
    if ELSEIF_THEN_PATTERN.search(code_part):
        keywords.append('ELSEIF_MULTILINE')

    return keywords, comment


def format_line(line, indent_level, in_label_section=False, label=None):
    """Format a line with proper indentation."""
    stripped = line.strip()

    if not stripped:
        return ''

    # Handle full-line comments
    if is_comment_line(stripped):
        return ' ' * (indent_level * INDENT_SIZE) + stripped

    # If we have a separated label, format it without indentation
    # and the rest of the line gets indented
    if label:
        return label  # Label goes on its own line without indent

    stripped_upper = stripped.upper()

    # Preprocessor directives (#if, #elif, #else, #endif) and BANK always at column 0
    # Don't confuse with 16-bit variables which also use # prefix (e.g., #LEVELADDR = ...)
    if (re.match(r'^#(IF|ELIF|ELSE|ENDIF)\b', stripped_upper) or
        re.match(r'^BANK\s+\d+', stripped_upper)):
        return stripped

    # include/incbin: respect preprocessor indent but not label section indent
    if stripped_upper.startswith('INCLUDE ') or stripped_upper.startswith('INCBIN '):
        effective_indent = indent_level - (1 if in_label_section else 0)
        effective_indent = max(0, effective_indent)
        return ' ' * (effective_indent * INDENT_SIZE) + stripped

    # Regular code line
    return ' ' * (indent_level * INDENT_SIZE) + stripped


def calculate_indentation_change(keywords):
    """Calculate how indentation should change based on keywords."""
    decrease_before = 0
    increase_after = 0

    for keyword in keywords:
        # Handle keywords that decrease before the line
        if keyword in INDENT_DECREASE_BEFORE:
            decrease_before = 1

        # Handle keywords that increase after the line
        if keyword in INDENT_INCREASE_AFTER:
            increase_after = 1

        # Handle middle keywords (ELSE, ELSEIF, CASE) - they decrease AND increase
        if keyword in INDENT_MIDDLE or keyword == 'CASE':
            decrease_before = 1
            increase_after = 1

        # Special handling for multi-line IF/ELSEIF
        if keyword == 'IF_MULTILINE':
            increase_after = 1
        if keyword == 'ELSEIF_MULTILINE':
            # Already handled by ELSEIF in INDENT_MIDDLE
            pass

        # END keyword (for PROCEDURE)
        if keyword == 'END':
            decrease_before = 1

    return decrease_before, increase_after


def lint_file(input_path, output_path=None, in_place=False):
    """Lint a CVBasic file."""
    input_path = Path(input_path)

    if not input_path.exists():
        print(f"Error: File not found: {input_path}")
        return False

    with open(input_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    output_lines = []
    indent_level = 0
    prev_blank = False
    in_label_section = False  # Track if we're in a label section (not PROCEDURE)

    for line in lines:
        line = line.rstrip('\n\r')

        # Handle blank lines - collapse multiple blanks to single blank
        if is_blank_line(line):
            if not prev_blank and output_lines:  # Don't add blank at start of file
                output_lines.append('')
                prev_blank = True
            continue

        prev_blank = False

        # Check for label
        label_text, rest_of_line = get_label(line)

        # If we have a label, check if PROCEDURE follows
        # CVBasic REQUIRES label and PROCEDURE to be on the same line
        if label_text:
            rest_upper = rest_of_line.strip().upper()
            has_procedure = rest_upper.startswith('PROCEDURE')

            if has_procedure:
                # If we were in a label section, close it first
                if in_label_section:
                    indent_level = max(0, indent_level - 1)
                    in_label_section = False

                # Keep label and PROCEDURE on same line
                # Format: "label: PROCEDURE"
                code_part, comment = remove_inline_comment(rest_of_line)
                code_part = normalize_spacing(code_part.strip())
                formatted_line = label_text + ' ' + code_part

                if comment:
                    formatted_line += ' ' + comment

                output_lines.append(formatted_line)

                # PROCEDURE increases indent
                indent_level += 1
                continue
            else:
                # Label without PROCEDURE
                # If we were already in a label section, close it first
                if in_label_section:
                    indent_level = max(0, indent_level - 1)

                # Put label on its own line at column 0
                output_lines.append(label_text)

                # Start new label section with increased indent
                indent_level += 1
                in_label_section = True

                # If there's code after the label, process it
                if rest_of_line.strip():
                    line = rest_of_line
                else:
                    continue

        # Handle full-line comments before extracting keywords
        stripped_line = line.strip()
        if is_comment_line(stripped_line):
            formatted = ' ' * (indent_level * INDENT_SIZE) + stripped_line
            output_lines.append(formatted)
            continue

        # Get keywords and comment
        keywords, comment = get_statement_keywords(line)

        # Calculate indentation changes
        decrease_before, increase_after = calculate_indentation_change(keywords)

        # Special handling: END closes label section first if we're in one
        if 'END' in keywords and in_label_section:
            indent_level = max(0, indent_level - 1)
            in_label_section = False

        # Apply decrease before (for WEND, NEXT, LOOP, END IF, END, ELSE, ELSEIF, CASE)
        if decrease_before:
            indent_level = max(0, indent_level - 1)

        # Format the line
        code_part, _ = remove_inline_comment(line)
        code_part = normalize_spacing(code_part.strip())
        code_part = align_const_statement(code_part)
        formatted = format_line(code_part, indent_level, in_label_section)

        # Re-attach comment if present
        if comment:
            # Add comment with some spacing
            if formatted:
                formatted += ' ' + comment
            else:
                formatted = comment

        output_lines.append(formatted)

        # Apply increase after (for WHILE, FOR, DO, IF...THEN, PROCEDURE, SELECT CASE)
        if increase_after:
            indent_level += 1

    # Join lines
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

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(output_text)

    print(f"Formatted: {input_path}" + (" (in-place)" if in_place else f" -> {output_path}"))
    return True


def main():
    if len(sys.argv) < 2:
        print("Usage: python cvblint.py <input.bas> [-i] [output.bas]")
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
