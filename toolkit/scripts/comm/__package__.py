#!/usr/bin/env python3
# -*- coding: utf-8 -*-

__package__


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