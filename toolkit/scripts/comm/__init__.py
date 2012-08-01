#!/usr/bin/env python3
# -*- coding: utf-8 -*-

__doc__	= "Computer-user communication library."


def set_terminal_title(title) :

    sys.stdout.write("\x1b]2;" + title + "\x07")
    sys.stdout.write("\033[2J")


def bold(str) :

    return("\x1b[1m" + str + "\x1b[0m")


def bell() :

    print("\a")


def communicate(level,
                message,
                moment = 'now',
                **output_streams) :

    for output_stream in output_streams.values() :
        if level        == 0 :
            print(message, 
                  file = output_stream)
            #pdb.set_trace()
        elif level      == 1 :
            #global terminal_dimensions
            bell()
            print("===\n" + bold(('{:^}').format(message)), 
                  file = output_stream)
        elif level      == 2 :
            bell()
            print("\n➫\t" + message, 
                  file = output_stream)
        elif level      == 3 :
            print(message, 
                  file = output_stream)
        else :
            raise NotImplementedError