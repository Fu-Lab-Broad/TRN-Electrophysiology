# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'ABFbot_ui.ui'
#
# Created by: PyQt5 UI code generator 5.13.0
#
# WARNING! All changes made in this file will be lost!


from PyQt5 import QtCore, QtGui, QtWidgets


class Ui_MainWindow(object):
    def setupUi(self, MainWindow):
        MainWindow.setObjectName("MainWindow")
        MainWindow.resize(420, 600)
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Fixed, QtWidgets.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(MainWindow.sizePolicy().hasHeightForWidth())
        MainWindow.setSizePolicy(sizePolicy)
        self.centralwidget = QtWidgets.QWidget(MainWindow)
        self.centralwidget.setObjectName("centralwidget")
        self.button_input_files = QtWidgets.QPushButton(self.centralwidget)
        self.button_input_files.setGeometry(QtCore.QRect(40, 20, 160, 40))
        self.button_input_files.setStyleSheet("font: 12pt \"MS Shell Dlg 2\";")
        self.button_input_files.setObjectName("button_input_files")
        self.button_clear_input = QtWidgets.QPushButton(self.centralwidget)
        self.button_clear_input.setGeometry(QtCore.QRect(220, 20, 160, 40))
        self.button_clear_input.setStyleSheet("font: 12pt \"MS Shell Dlg 2\";")
        self.button_clear_input.setObjectName("button_clear_input")
        self.button_output_folder = QtWidgets.QPushButton(self.centralwidget)
        self.button_output_folder.setGeometry(QtCore.QRect(40, 260, 160, 40))
        self.button_output_folder.setStyleSheet("font: 12pt \"MS Shell Dlg 2\";")
        self.button_output_folder.setObjectName("button_output_folder")
        self.button_run = QtWidgets.QPushButton(self.centralwidget)
        self.button_run.setGeometry(QtCore.QRect(220, 540, 160, 40))
        self.button_run.setStyleSheet("font: 12pt \"MS Shell Dlg 2\";")
        self.button_run.setObjectName("button_run")
        self.label_status = QtWidgets.QLabel(self.centralwidget)
        self.label_status.setGeometry(QtCore.QRect(40, 540, 160, 40))
        self.label_status.setStyleSheet("font: 12pt \"MS Shell Dlg 2\";")
        self.label_status.setText("")
        self.label_status.setObjectName("label_status")
        self.text_output = QtWidgets.QTextBrowser(self.centralwidget)
        self.text_output.setGeometry(QtCore.QRect(40, 310, 340, 50))
        self.text_output.setObjectName("text_output")
        self.listWidget_input = QtWidgets.QListWidget(self.centralwidget)
        self.listWidget_input.setGeometry(QtCore.QRect(40, 70, 340, 180))
        self.listWidget_input.setObjectName("listWidget_input")
        self.progressBar = QtWidgets.QProgressBar(self.centralwidget)
        self.progressBar.setGeometry(QtCore.QRect(40, 500, 340, 20))
        self.progressBar.setProperty("value", 20)
        self.progressBar.setObjectName("progressBar")
        self.output_prefix = QtWidgets.QPlainTextEdit(self.centralwidget)
        self.output_prefix.setGeometry(QtCore.QRect(223, 390, 160, 30))
        self.output_prefix.viewport().setProperty("cursor", QtGui.QCursor(QtCore.Qt.IBeamCursor))
        self.output_prefix.setStyleSheet("font: 12pt \"MS Shell Dlg 2\";")
        self.output_prefix.setInputMethodHints(QtCore.Qt.ImhNone)
        self.output_prefix.setVerticalScrollBarPolicy(QtCore.Qt.ScrollBarAlwaysOff)
        self.output_prefix.setHorizontalScrollBarPolicy(QtCore.Qt.ScrollBarAlwaysOff)
        self.output_prefix.setLineWrapMode(QtWidgets.QPlainTextEdit.NoWrap)
        self.output_prefix.setObjectName("output_prefix")
        self.label = QtWidgets.QLabel(self.centralwidget)
        self.label.setGeometry(QtCore.QRect(40, 390, 170, 30))
        self.label.setStyleSheet("font: 12pt \"MS Shell Dlg 2\";")
        self.label.setObjectName("label")
        self.output_format = QtWidgets.QComboBox(self.centralwidget)
        self.output_format.setGeometry(QtCore.QRect(223, 440, 160, 30))
        self.output_format.setStyleSheet("font: 12pt \"MS Shell Dlg 2\";")
        self.output_format.setObjectName("output_format")
        self.output_format.addItem("")
        self.output_format.addItem("")
        self.label_2 = QtWidgets.QLabel(self.centralwidget)
        self.label_2.setGeometry(QtCore.QRect(40, 440, 170, 30))
        self.label_2.setStyleSheet("font: 12pt \"MS Shell Dlg 2\";")
        self.label_2.setObjectName("label_2")
        MainWindow.setCentralWidget(self.centralwidget)

        self.retranslateUi(MainWindow)
        QtCore.QMetaObject.connectSlotsByName(MainWindow)

    def retranslateUi(self, MainWindow):
        _translate = QtCore.QCoreApplication.translate
        MainWindow.setWindowTitle(_translate("MainWindow", "ABFbot"))
        self.button_input_files.setText(_translate("MainWindow", "Select File(s)"))
        self.button_clear_input.setText(_translate("MainWindow", "Clear"))
        self.button_output_folder.setText(_translate("MainWindow", "Select Output Folder"))
        self.button_run.setText(_translate("MainWindow", "Run"))
        self.label.setText(_translate("MainWindow", "Output Filename Prefix"))
        self.output_format.setItemText(0, _translate("MainWindow", "Pharmacology"))
        self.output_format.setItemText(1, _translate("MainWindow", "VM"))
        self.label_2.setText(_translate("MainWindow", "Data Summary Format "))


if __name__ == "__main__":
    import sys
    app = QtWidgets.QApplication(sys.argv)
    MainWindow = QtWidgets.QMainWindow()
    ui = Ui_MainWindow()
    ui.setupUi(MainWindow)
    MainWindow.show()
    sys.exit(app.exec_())
