# pl (sqlite)
sudo cpan install DBI
sudo cpan install DBD::SQLite


# cs
# sudo apt-get install mono-devel # not required, enough this
sudo apt install mono-mcs
# r
sudo apt-get install r-base 
# p
sudo apt-get install fp-compiler
# f95
sudo apt install gfortran


# Analiza wydajności pustych pętli w 16 językach

[TOC]

## Opis projektu

Nie wiem, jakie są wasze wymarzone prezenty gwiazdkowe, ale mój wymarzony to kawałek ciekawego kodu. I właśnie taki prezent dostałem blisko miesiąc temu.

Mój przyjaciel wysłał mi w e-mailu [Kod źródłowy programu](https://www.dropbox.com/s/s9dy1jabkzxzls6/loopspeed.zip?dl=1), który mierzył czasy wykonywania pustych pętli w czterech różnych językach programowania. Dopisałem testy dla dwunastu innych języków, lekko zautomatyzowałem testowanie i przeanalizowałem wyniki.

W tym wpisie pokażę jak wyglądają i jak szybko działają programy wykonujące puste pętle językach: Matlab, Bash, SQL, Mathematica, C#, JavaScript, Python, Ruby, Perl, R, Php, Fortran 95, C++, C, Pascal i Java. Do logowania danych wykorzystamy plik tekstowy oraz silnik bazodanowy SQLite. Analizę danych przeprowadzimy w programie Mathematica. 

## Instalacja

## Framework

## Dataflow

## Analiza

## Wyniki

[![r.png](https://s27.postimg.org/jzgak8vab/image.png)](https://postimg.org/image/rffk61izj/)


+ `file` - plik i rozszerzenie języka
+ `size` - ilość kroków pętli
+ `time` - czas wykonywania programu
+ `speed` - ilość iteracji na sekundę

