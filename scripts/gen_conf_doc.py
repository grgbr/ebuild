#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os
import argparse
import textwrap
from kconfiglib import Kconfig, Symbol, Choice, MenuNode, BOOL

# Wrap text lines while preserving newlines
class HelpWrap(textwrap.TextWrapper):

    def wrap(self, text):
        split_text = text.split('\n')
        lines = []
        for line in textwrap.TextWrapper.wrap(self, split_text[0]):
            lines.append(line)
        for para in split_text[1:]:
            if len(para):
                for line in textwrap.TextWrapper.wrap(self, para):
                    lines.append(line)
            else:
                lines.append(self.subsequent_indent)
        
        return lines


def get_prompt(node):
    if node.prompt:
        return node.prompt[0]
    else:
        return None


def get_value(node):
    if node.item.type is BOOL:
        return "1"

    return node.item.str_value


def make_brief(node):
    prompt = get_prompt(node)
    if prompt:
        return ' * @brief   {brief}\n'.format(brief = prompt)
    else:
        return ""


def make_details(node):
    if node.help:
        wrapper = HelpWrap(width = 80,
                           initial_indent = ' * ',
                           subsequent_indent = ' * ')
        details = wrapper.fill(node.help)
        return ' * @details\n{details}\n'.format(details = details)
    else:
        return ""


def print_symbol(node, outfile):
    print('/**\n' \
          ' * @def     CONFIG_{name}\n' \
          '{brief}' \
          '{details}' \
          ' */\n' \
          '#define CONFIG_{name} {value}\n'.format(name=node.item.name,
                                                   brief=make_brief(node),
                                                   details=make_details(node),
                                                   value=get_value(node)),
          file = outfile)


def print_items(node, outfile):
    while node:
        if isinstance(node.item, Symbol):
            print_symbol(node, outfile)

        if node.list:
            print_items(node.list, outfile)

        node = node.next


def print_kconf(kconf, project, outfile):
    print('/**\n' \
          ' * @file\n' \
          ' * {project} build configuration\n' \
          ' */\n'.format(project = 'DPack'), file = outfile)
    print('#ifndef _{project}_CONFDOC_H\n' \
          '#define _{project}_CONFDOC_H\n'.format(project = project.upper()),
          file = outfile)
    print_items(kconf.top_node, outfile)
    print('#endif /* _{project}_CONFDOC_H */'.format(project = project.upper()),
          file = outfile)


def main():
    global arg0

    arg0 = os.path.basename(sys.argv[0])

    parser = argparse.ArgumentParser(description='eBuild build configuration '
                                                 'documentation generator')
    parser.add_argument('kconf_fpath',
                        nargs = 1,
                        default = None,
                        metavar = 'KCONFIG_FILEPATH',
                        help = 'Pathname to KConfig file')
    parser.add_argument('project_name',
                        nargs = 1,
                        default = None,
                        metavar = 'PROJECT_NAME',
                        help = 'Name of project to document')
    parser.add_argument('-o',
                        '--output',
                        nargs = 1,
                        type = argparse.FileType('w'),
                        default = None,
                        dest = 'out_fpath',
                        metavar = 'OUTPUT_FILEPATH',
                        help = 'Pathname to output file')

    args = parser.parse_args()
    
    try:
        kconf = Kconfig(args.kconf_fpath[0])
    except Exception as e:
        print("{}: KConfig parsing failed: {}.".format(arg0, e),
              file=sys.stderr)
        sys.exit(1)

    if not len(kconf.defined_syms):
        print("{}: Empty KConfig file.".format(arg0), file=sys.stderr)
        sys.exit(1)

    if args.out_fpath:
        out = args.out_fpath[0]
    else:
        out = sys.stdout
    try:
        print_kconf(kconf, args.project_name[0], out)
    except Exception as e:
        print("{}: KConfig documentation generation failed: {}.".format(arg0,
                                                                        e),
              file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
