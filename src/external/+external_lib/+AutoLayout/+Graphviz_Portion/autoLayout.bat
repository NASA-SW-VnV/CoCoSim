for %%f in (*.dot) do (
            dot "%%~nf.dot" -Tplain -o "%%~nf-plain.txt"
            dot "%%~nf.dot" -Tpdf -o "%%~nf.pdf"
)