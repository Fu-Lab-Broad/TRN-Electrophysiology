# pip install openpyxl
# pip install xlsxwriter
import pandas as pd
import os

def csv_to_excel(filepath):
    df = pd.read_csv(filepath, names=list(range(50)), skip_blank_lines=False)
    writer = pd.ExcelWriter(filepath.replace('.csv', '.xlsx'), engine='xlsxwriter')
    df.to_excel(writer, sheet_name= 'sheet1',index=False,header=False)
    worksheet = writer.sheets['sheet1']
    workbook = writer.book
    cell_format = workbook.add_format({'bold':True})
    for row in df.index[df[1]=='1']:
        worksheet.set_row(row,None,cell_format)
    writer.save()
    writer.close()
    os.remove(filepath)
