' The purpose of this script is beautify the financials in Excel
' The description column in the financials inculde beautification codes
' The script iterates across the description column, inspects the codes and executes the changes.

' NOTE: this script is not complete yet. The below code illustrates how to interate down a column; 
'    however, it does not show how iterate across the beautification codes yet.
'    I will update this script as I have time.

' orginal source: http://stackoverflow.com/questions/15417544/how-to-automatically-insert-a-blank-row-after-a-group-of-data

sub AddBlankRows()
'
dim iRow as integer
range("a1").select
'
irow=1
'
do 
'
if cells(irow+1, 1)<>cells(irow,1) then
    cells(irow+1,1).entirerow.insert shift:=xldown
    irow=irow+2
else
    irow=irow+1
end if
'
loop while not cells (irow,1).text=""
'
end sub