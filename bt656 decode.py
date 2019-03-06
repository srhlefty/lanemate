# -*- coding: utf-8 -*-
"""
Created on Thu Oct 18 12:27:48 2018

@author: Steven
"""
import csv
import numpy as np
import matplotlib.pyplot as plt


def ycbcr2rgb(im):
    xform = np.array([[1, 0, 1.402], [1, -0.34414, -.71414], [1, 1.772, 0]])
    rgb = im.astype(np.float)
    rgb[:,:,[1,2]] -= 128
    rgb = rgb.dot(xform.T)
    np.putmask(rgb, rgb > 255, 255)
    np.putmask(rgb, rgb < 0, 0)
    return np.uint8(rgb)

        
# first column = time, second column = bus value
file_name = "new_circuit.txt"
codes = []

with open(file_name) as f:
    reader = csv.reader(f, delimiter=',')
    line_count = 0
    for row in reader:
        if line_count == 0:
            print("header ignored")
        else:
           codes.append(int(row[1],16))
        line_count = line_count + 1

print('Processed ',line_count,'lines')



line = 0
line_sample = 0
column = 0
vblank_old = False
imgwidth = 720
imgheight = 525
state2 = "Waiting"
state3 = "Cb1"
state4 = "Y1"
state5 = "Cr1"
state6 = "Y2"
state = state2

code_dict = {
             0b1000 : "Field 0, not blanked, SAV",
             0b1001 : "Field 0, not blanked, EAV",
             0b1010 : "Field 0,     blanked, SAV",
             0b1011 : "Field 0,     blanked, EAV",
             0b1100 : "Field 1, not blanked, SAV",
             0b1101 : "Field 1, not blanked, EAV",
             0b1110 : "Field 1,     blanked, SAV",
             0b1111 : "Field 1,     blanked, EAV",
             }

img = np.zeros((imgheight,imgwidth,3))

delta = 0
for i in range(3,len(codes)):
    if (codes[i-3] == 0xFF) and (codes[i-2] == 0) and (codes[i-1] == 0):
        # found preamble, get XY
        XY = codes[i] >> 4
        #print("Code at row",i-3+2,":",code_dict[XY])
        
        # I'll get more than one of these before the actual video starts
        # since this code is repeated throughout the blanking lines
        if XY == 0b1111:
            print("Field 1 vblank")
            line = 0
        elif XY == 0b1011:
            print("Field 0 vblank")
            line = 1
        elif XY == 0b1000:
            print("Start of line, field 0")
        elif XY == 0b1001:
            print("End of line, field 0")
        elif XY == 0b1100:
            print("Start of line, field 1")
        elif XY == 0b1101:
            print("End of line, field 1")
            
        if XY == 0b1000 or XY == 0b1100:
            # start of a line
            column = 0
            line_sample = 0
            state = state3
            continue

    if state == state3:
        # Image is (Y,Cb,Cr) so this is [1]
        img[line,column,1] = codes[i]
        line_sample = line_sample + 1
        state = state4
    
    elif state == state4:
        # Image is (Y,Cb,Cr) so this is [0]
        img[line,column,0] = codes[i]
        line_sample = line_sample + 1
        state = state5
    
    elif state == state5:
        # Image is (Y,Cb,Cr) so this is [2]
        img[line,column,2] = codes[i]
        line_sample = line_sample + 1
        # pixel complete!
        column = column + 1
        state = state6
    
    elif state == state6:
        # I only get a Y for this pixel
        img[line,column,0] = codes[i]
        img[line,column,1] = img[line,column-1,1]
        img[line,column,2] = img[line,column-1,2]
        column = column + 1
        line_sample = line_sample + 1
        if line_sample == 1440:
            # line complete!
            print("line",line,"complete (",column,"px)")
            line = line + 2
            state = state2
        else:
            state = state3
     
#==============================================================================
plt.imshow(ycbcr2rgb(img))
        