$env:PATH = "$env:PATH;C:\Users\ntdde\AppData\Local\bin\NASM"
function compile {
  param($d)
  nasm -f win64 "$d.s" -o "$d.o"; clang "$d.o" -o "$d.exe"
}

