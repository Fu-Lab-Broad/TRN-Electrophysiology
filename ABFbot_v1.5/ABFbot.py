import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
pd.options.mode.chained_assignment = None
import pyabf
import sys
import os
import datetime
from scipy.signal import find_peaks
from scipy.signal import peak_widths
from scipy import optimize
from PyQt5.QtCore import *
from PyQt5.QtWidgets import *
from ABFbot_functions import *
from ABFbot_detect_bursts import *
from ABFbot_process_abf import *
from ABFbot_ui import Ui_MainWindow
from ABFbot_csv_to_excel import *
from ABFbot_settings import *

class Thread_run_all_files(QThread):
    signal = pyqtSignal('PyQt_PyObject')

    def __init__(self):
        QThread.__init__(self)
        self.input_base_dir = './'
        self.output_base_dir = None
        self.filepath_list = []
        self.filename_list = [0]
        self.num_files = 0
        self.data_format = None
        self.output_prefix = None
    
    def run(self):
        df = pd.DataFrame()
        for index, filepath in enumerate(self.filepath_list):
            df = process_abf(filepath, df, self.output_base_dir)
            progress = (index+1)/self.num_files * 100
            self.signal.emit(progress)
        
        if self.data_format == 'Pharmacology':
            df = df[[
                'File',
                'Sweep',
                'Burst Index',
                'RMP (mV)',
                'Hyperpolarization amplitude (mV)',
                '# Bursts',
                '# Events',
                '# AP in this burst',
                'AP Freq (Hz)',
                'AP Threshold (mV)',
                'Latency (ms)',
                'AHP (mV)',
                'IBI (ms)',
                'IR',
                '# Total AP'
            ]]
            text_file = open(self.output_base_dir + '/' + self.output_prefix + 'Summary_Pharmacology.csv', "w")
            
            df_no_bursts = df[df['Burst Index'].isna()]
            df_no_bursts = df_no_bursts.drop('Burst Index', axis=1)
            text_file.write('No Bursts')
            text_file.write('\n')
            text_file.write(df_no_bursts.to_csv(index=False).replace('\r\n', '\n'))
            text_file.write('\n')

            if ~df['Burst Index'].isna().all():
                max_num_burst = int(df['Burst Index'].max())
                for index in range(1, max_num_burst+1):
                    df_sub = df[df['Burst Index'] == index]
                    df_sub = df_sub.drop('Burst Index', axis=1)
                    text_file.write('Burst ' + str(index))
                    text_file.write('\n')
                    text_file.write(df_sub.to_csv(index=False).replace('\r\n', '\n'))
                    text_file.write('\n')
            text_file.close()
            csv_to_excel(self.output_base_dir + '/' + self.output_prefix + 'Summary_Pharmacology.csv')

        if self.data_format == 'VM':
            df1 = df[[
                'File',
                'Sweep',
                'Current Steps (pA)',
                'RMP (mV)',
                'Hyperpolarization amplitude (mV)',
                '# Bursts',
                '# Events',
                '# Total AP',
                '# LTS',
                'Tonically firing',
                'Tonic Frequency (Hz)',
                'IR'
            ]]
            df1 = df1.drop_duplicates()
            
            df2 = df[[
                'File',
                'Burst Index',
                'Sweep',
                'Current Steps (pA)',
                'RMP (mV)',
                'Hyperpolarization amplitude (mV)',
                'Latency (ms)',
                'Duration (ms)',
                'AP Freq (Hz)',
                '# AP in this burst',
                'AP Threshold (mV)',
                'AHP (mV)',           
                'IBI (ms)',
                'Avg ISI of FIRST 3 spikes (ms)',
                'Initial Frequency (Hz)',
                'Avg ISI of LAST 3 spikes (ms)',
                'Final epoch Frequency (Hz)'
            ]]
            
            text_file = open(self.output_base_dir + '/' + self.output_prefix + 'Summary_VM.csv', "w")
            text_file.write('Summary\n')
            text_file.write(df1.to_csv(index=False).replace('\r\n', '\n'))
            text_file.write('\n\n')

            df_no_bursts = df2[df2['Burst Index'].isna()]
            df_no_bursts = df_no_bursts.drop('Burst Index', axis=1)
            text_file.write('No Bursts')
            text_file.write('\n')
            text_file.write(df_no_bursts.to_csv(index=False).replace('\r\n', '\n'))
            text_file.write('\n')

            if ~df2['Burst Index'].isna().all():
                max_num_burst = int(df2['Burst Index'].max())
                for index in range(1, max_num_burst+1):
                    df_sub = df2[df2['Burst Index'] == index]
                    df_sub = df_sub.drop('Burst Index', axis=1)
                    text_file.write('Burst ' + str(index))
                    text_file.write('\n')
                    text_file.write(df_sub.to_csv(index=False).replace('\r\n', '\n'))
                    text_file.write('\n')
            text_file.close()
            csv_to_excel(self.output_base_dir + '/' + self.output_prefix + 'Summary_VM.csv') 

class MyMainWindow(QMainWindow, Ui_MainWindow):
    def __init__(self, parent=None):
        super(MyMainWindow, self).__init__(parent)
        self.setupUi(self)
        self.center()
        self.setFixedSize(420, 600)
        self.setWindowTitle("ABFbot v1.5")
        self.progressBar.setProperty("value", 0)
        self.change_progressbar_color('yellow')

        self.input_base_dir = './'
        self.output_base_dir = None
        self.filepath_list = []
        self.filename_list = [0]
        self.num_files = 0
        self.data_format = None
        self.output_format.setCurrentText(DEFAULT_OUTPUT_FORMAT)
        self.data_format = self.output_format.currentText()

        self.button_input_files.clicked.connect(self.update_file_list)
        self.button_clear_input.clicked.connect(self.clear)
        self.button_output_folder.clicked.connect(self.update_output_dir)
        self.button_run.clicked.connect(self.run_all_files)
    
    def change_progressbar_color(self, color):
        template_css = """QProgressBar::chunk { background: %s; }"""
        css = template_css % color
        self.progressBar.setStyleSheet(css)

    def center(self):  # center align window
        qr = self.frameGeometry()
        cp = QDesktopWidget().availableGeometry().center()
        qr.moveCenter(cp)
        self.move(qr.topLeft())

    def update_file_list(self):
        added_filepath_list = QFileDialog.getOpenFileNames(self,
                                                            'open file',
                                                            self.input_base_dir,
                                                            "abf Files (*.abf)")[0]
        if len(added_filepath_list) > 0:
            self.filepath_list += added_filepath_list
            self.num_files = len(self.filepath_list)
            self.filename_list = self.filename_list * self.num_files

            self.listWidget_input.clear()
            for i in range(self.num_files):
                last_slash_index = self.filepath_list[i].rfind('/')
                self.input_base_dir = self.filepath_list[i][:last_slash_index]
                self.filename_list[i] = self.filepath_list[i][last_slash_index + 1:]
                self.listWidget_input.addItem(self.filename_list[i])

            if self.output_base_dir == None:
                self.output_base_dir = self.filepath_list[0][:last_slash_index]
                self.text_output.setText(self.output_base_dir)
    
    def clear(self):
        self.progressBar.setProperty("value", 0)
        self.label_status.setText("")
        self.output_base_dir = None
        self.filepath_list = []
        self.filename_list = [0]
        self.num_files = 0

        self.text_output.clear()
        self.listWidget_input.clear()

    def update_output_dir(self):
        self.output_base_dir = QFileDialog.getExistingDirectory(None,
                                                                'Select a folder:',
                                                                self.input_base_dir,
                                                                QFileDialog.ShowDirsOnly)
        
        self.text_output.setText(self.output_base_dir)
    
    def update_progress(self, progress):
        self.progressBar.setProperty('value', '{:.0f}'.format(progress))
        if progress == 100:
            self.button_run.setEnabled(True)
            self.button_input_files.setEnabled(True)
            self.button_clear_input.setEnabled(True)
            self.button_output_folder.setEnabled(True)
            self.output_format.setEnabled(True)
            self.label_status.setText("Done")
            self.change_progressbar_color('LawnGreen')
    
    def run_all_files(self):
        self.button_run.setEnabled(False)
        self.button_input_files.setEnabled(False)
        self.button_clear_input.setEnabled(False)
        self.button_output_folder.setEnabled(False)
        self.output_format.setEnabled(False)

        self.label_status.setText("Processing...")
        self.progressBar.setProperty("value", 0)
        self.change_progressbar_color('yellow')
        self.data_format = self.output_format.currentText()
        self.run()

    def run(self):
        df = pd.DataFrame()
        for index, filepath in enumerate(self.filepath_list):
            df = process_abf(filepath, df, self.output_base_dir)
            progress = (index+1)/self.num_files * 100
            print('*********************************** ' + '{:.0f}'.format(progress) + '%')
            # self.progressBar.setProperty('value', '{:.0f}'.format(progress))
            self.update_progress(progress)

        if 'Pharmacology' in self.data_format:
            df = df[[
                'File',
                'Sweep',
                'Burst Index',
                'RMP (mV)',
                'Hyperpolarization amplitude (mV)',
                '# Bursts',
                '# Events',
                '# AP in this burst',
                'AP Freq (Hz)',
                'AP Threshold (mV)',
                'Latency (ms)',
                'AHP (mV)',
                'IBI (ms)',
                'IR',
                '# Total AP'
            ]]
            text_file = open(self.output_base_dir + '/' + self.output_prefix.toPlainText()+ 'Summary_Pharmacology.csv', "w")
            
            df_no_bursts = df[df['Burst Index'].isna()]
            df_no_bursts = df_no_bursts.drop('Burst Index', axis=1)
            text_file.write('No Bursts')
            text_file.write('\n')
            text_file.write(df_no_bursts.to_csv(index=False).replace('\r\n', '\n'))
            text_file.write('\n')

            if ~df['Burst Index'].isna().all():
                max_num_burst = int(df['Burst Index'].max())
                for index in range(1, max_num_burst+1):
                    df_sub = df[df['Burst Index'] == index]
                    df_sub = df_sub.drop('Burst Index', axis=1)
                    text_file.write('Burst ' + str(index))
                    text_file.write('\n')
                    text_file.write(df_sub.to_csv(index=False).replace('\r\n', '\n'))
                    text_file.write('\n')
            text_file.close()
            if 'Megan' in self.data_format:
                csv_to_excel(self.output_base_dir + '/' + self.output_prefix.toPlainText()+ 'Summary_Pharmacology.csv') 
        if 'VM' in self.data_format:
            df1 = df[[
                'File',
                'Sweep',
                'Current Steps (pA)',
                'RMP (mV)',
                'Hyperpolarization amplitude (mV)',
                '# Bursts',
                '# Events',
                '# Total AP',
                '# LTS',
                'Tonically firing',
                'Tonic Frequency (Hz)',
                'IR'
            ]]
            df1 = df1.drop_duplicates()
            
            df2 = df[[
                'File',
                'Burst Index',
                'Sweep',
                'Current Steps (pA)',
                'RMP (mV)',
                'Hyperpolarization amplitude (mV)',
                'Latency (ms)',
                'Duration (ms)',
                'AP Freq (Hz)',
                '# AP in this burst',
                'AP Threshold (mV)',
                'AHP (mV)',           
                'IBI (ms)',
                'Avg ISI of FIRST 3 spikes (ms)',
                'Initial Frequency (Hz)',
                'Avg ISI of LAST 3 spikes (ms)',
                'Final epoch Frequency (Hz)'
            ]]
            
            text_file = open(self.output_base_dir + '/' + self.output_prefix.toPlainText() + 'Summary_VM.csv', "w")
            text_file.write('Summary\n')
            text_file.write(df1.to_csv(index=False).replace('\r\n', '\n'))
            text_file.write('\n\n')

            df_no_bursts = df2[df2['Burst Index'].isna()]
            df_no_bursts = df_no_bursts.drop('Burst Index', axis=1)
            text_file.write('No Bursts')
            text_file.write('\n')
            text_file.write(df_no_bursts.to_csv(index=False).replace('\r\n', '\n'))
            text_file.write('\n')

            if ~df2['Burst Index'].isna().all():
                max_num_burst = int(df2['Burst Index'].max())
                for index in range(1, max_num_burst+1):
                    df_sub = df2[df2['Burst Index'] == index]
                    df_sub = df_sub.drop('Burst Index', axis=1)
                    text_file.write('Burst ' + str(index))
                    text_file.write('\n')
                    text_file.write(df_sub.to_csv(index=False).replace('\r\n', '\n'))
                    text_file.write('\n')
            text_file.close()
            if 'Megan' in self.data_format:
                csv_to_excel(self.output_base_dir + '/' + self.output_prefix.toPlainText() + 'Summary_VM.csv') 

if __name__ == "__main__":
    app = QApplication(sys.argv)
    myWin = MyMainWindow()
    myWin.show()
    sys.exit(app.exec_())

print('Done')
