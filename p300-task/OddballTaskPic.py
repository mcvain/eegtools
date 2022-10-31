# OddballTaskPic.py
# by J.Yagi 2019/06/03 
# modified by Hyonyoung Shin 2022/10/31
# <hyonyoung.shin@utexas.edu> 

# task visualization to evoke visual oddball P300 signal.
# allows presentation of stimuli at specified intervals and output to LSL for time synchronization
# press space bar to start the experiment, or to pause the experiment, or to quit the experiment 
# the following codes are pushed to the LSL: target (rare) stimulus:[2]，common stimulus:[1]，no stimulus:[0]

import sys
import random
from time import perf_counter as pc                                         # high performance timer

from PyQt5.QtWidgets import QApplication, QDesktopWidget, QLabel, QWidget   # for the GUI programming 
from PyQt5.QtGui import QPainter, QColor, QFont, QPen, QPixmap
from PyQt5.QtCore import Qt, QTimer, QRectF, pyqtSignal

####################################################################
## Parameters 
####################################################################
frameRate = 10                      # display frame rate
printsec = 1                        # stimulus display duration in seconds 
sumOfStimulus = 10                  # total number of stimuli 
ratioOfTarget = 0.2                 # ratio of the "rare" stimuli a.k.a. target (suggested: below 0.5)
targetPic = "stimulus/blue.png"     # image file of "rare" stimulus 
standardPic = "stimulus/red.png"    # image file of "common" stimulus 
activateLSL = False                 # boolean for whether to activate LSL or proceed to test without LSL 
display_mode = "fullscreen"
####################################################################
if activateLSL:
    from pylsl import StreamInfo, StreamOutlet                                 

class Stimulus:
    def __init__(self,stimulusOrder):
        self.on = 0                 # stimulus state output to LSL 
        self.stimulusOrder = stimulusOrder
        self.counterStimulus = 0
        self.next_time = pc() + printsec

    def resetTimer(self):
        self.next_time = pc() + printsec

    def draw(self, ctime, window):
        painter = QPainter(window)

        if (self.on == 1) or (self.on == 2):
            if self.stimulusOrder[self.counterStimulus] == 0: 
                pic = QPixmap(targetPic)                    # load the image
                x = int((window.size().width() - pic.width()) / 2)  # place stimulus at midpoint of window 
                y = int((window.size().height() - pic.height()) / 2)
                painter.drawPixmap(x,y,pic)               # supply coordinates 

            elif self.stimulusOrder[self.counterStimulus] == 1:
                pic = QPixmap(standardPic)
                x = int((window.size().width() - pic.width()) / 2)
                y = int((window.size().height() - pic.height()) / 2)
                painter.drawPixmap(x,y,pic)

        if ctime >= self.next_time:                         # if finished waiting for next stimulus
            self.next_time += printsec
            if (self.on == 1) or (self.on == 2):
                #print(pc()) # uncomment to display the timing/latency 
                self.counterStimulus = self.counterStimulus + 1
                self.on = 0
                print(self.counterStimulus)                 # print stimulus order
            else:
                if self.stimulusOrder[self.counterStimulus] == 0:
                    self.on = 1
                elif self.stimulusOrder[self.counterStimulus] == 1:
                    self.on = 2

class MainWindow(QWidget):
    def __init__(self):
        super().__init__()
        print("###  [Space] to Start and Pause/Unpause  ###")
        self.base_time = pc()
        self.OrderStimulus()
        self.initStimulus()
        self.initUI()

        if display_mode == "fullscreen":
            self.showFullScreen()
        elif display_mode == "borderless":
            self.showMaximized()
        elif display_mode == "window":
            self.resize(700, 700)
            self.show()
        
        if activateLSL:
            info = StreamInfo('Oddballstimulus', 'stimulation', 1, 100, 'float32', 'oddball_20221031')
            self.outlet = StreamOutlet(info)

    def initUI(self):
        self.setWindowTitle("Oddball-Task Stimulus")
    
        self.timer = QTimer(self)
        self.timer.timeout.connect(self.update)             # update is linked with paintEvent

    # prepare the order of stimuli 
    def OrderStimulus(self):         
        self.stimulusOrder = list()                         # open the list 

        sumOfTarget =  int(sumOfStimulus*ratioOfTarget)

        # fill the list with the desired number of 0 and 1 stimuli events
        for i in range(sumOfTarget):
            self.stimulusOrder.append(0)
        for i in range(sumOfStimulus-sumOfTarget):
            self.stimulusOrder.append(1)

        # then shuffle! 
        random.shuffle(self.stimulusOrder)           

    # defines the stimulus 
    def initStimulus(self):
        self.stim = Stimulus(self.stimulusOrder)

    # to be called with a valid key press input 
    def keyPressEvent(self, e):                            
        if e.key() == Qt.Key_Space:
            if (self.stim.counterStimulus >= sumOfStimulus):# quit functionality 
                self.timer.start()
                sys.exit()
            elif self.timer.isActive():                     # pause functionality
                self.timer.stop()
            else:                                           # resume functionality
                self.stim.resetTimer()
                self.timer.start(frameRate)                 # may not be needed

    # to be called with every update event 
    def paintEvent(self, QPaintEvent):      
        curr_time = pc()
        if (self.stim.counterStimulus >= sumOfStimulus): # if the total number of stimuli is reached 
            print("###  [Space] to Exit from This App  ###")
            self.timer.stop()
        else:
            self.stim.draw(curr_time, self)
            stimu = [int(self.stim.on)]      
            if activateLSL:
                self.outlet.push_sample(stimu)
                print(stimu) # this value is pushed to LSL

if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = MainWindow()                                   # create MainWindow instance
    # window.resize(700, 700)                                 # change screen size 
    sys.exit(app.exec_())
