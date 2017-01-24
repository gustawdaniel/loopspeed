# Analiza wydajności pustych pętli w 16 językach

[TOC]

## Opis projektu

Nie wiem, jakie są wasze wymarzone prezenty gwiazdkowe, ale mój wymarzony to kawałek ciekawego kodu. I właśnie taki prezent dostałem blisko miesiąc temu.

Mój przyjaciel wysłał mi w e-mailu [Kod źródłowy programu](https://www.dropbox.com/s/s9dy1jabkzxzls6/loopspeed.zip?dl=1), który mierzył czasy wykonywania pustych pętli w czterech różnych językach programowania. Dopisałem testy dla dwunastu innych języków, lekko zautomatyzowałem testowanie i przeanalizowałem wyniki.

W tym wpisie pokażę jak wyglądają i jak szybko działają programy wykonujące puste pętle językach: Matlab, Bash, SQL, Mathematica, C#, JavaScript, Python, Ruby, Perl, R, Php, Fortran 95, C++, C, Pascal i Java. Do logowania danych wykorzystamy plik tekstowy oraz silnik bazodanowy SQLite. Analizę danych przeprowadzimy w programie Mathematica. 

## Instalacja

Instalację projektu na czystym Lubuntu 16.04.1 LTS wymaga wpisania trzech komend:

```
sudo apt-get install git
git clone -depth=1 http://github.com/gustawdaniel/loopspeed && cd loopspeed
bash install.sh
```

Skrypt instalacyjny `install.sh` wykonuje instalację wymaganych kompilatorów i języków:

```
#!/usr/bin/env bash

sudo apt-get install sqlite3 g++ mono-mcs openjdk-9-jdk-headless mysql-server gfortran fp-compiler r-base nodejs-legacy ruby php
```

dorzuca do tego paczki perla, których używamy do komunikacji z bazą SQLite

```
sudo cpan install DBI DBD::SQLite
```

I tworzy bazę do przechowywania wyników pomiarów:

```
sqlite3 log/log.db \
"create table IF NOT EXISTS log (
    id INTEGER PRIMARY KEY,
    name VARCHAR(255),
    size UNSIGNED INTEGER,
    time DECIMAL(8,2),
    git CHAR(41)
);"
```

### Problemy z logowaniem do MySQL  

Niestety, a raczej niestety dla mnie, od kilku miesięcy MySQL nie pozwala już domyślnie logować się komendą `mysql -u root`, wymaga `sudo mysql -u root`. Jest to zrozumiałe ze względów bezpieczeństwa i na pewno pomaga na serwerach produkcyjnych, ale z drugiej strony jest to niewygodne przy bawieniu się kodem w domu. Jeśli twój komputer to maszyna lokalna i tak jak ja nie chcesz używać `sudo` do każdego łączenia z bazą w bashu, możesz wykonać następujący [manewr](http://stackoverflow.com/questions/38098505/mysql-works-with-sudo-but-without-not-ubuntu-16-04-mysql-5-7-12-0ubuntu1-1):

```
sudo mysql -u root
DROP USER 'root'@'localhost';
CREATE USER 'root'@'%' IDENTIFIED BY '';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%';
FLUSH PRIVILEGES;
exit
```

w ten sposób przywrócisz `mysql -u root` jako działającą metodę łączenia się z bazą. Prezentowany tutaj program używa właśnie takiej metody. Jeśli nie chcesz zmieniać ustawień bazy danych zawsze możesz zmodyfikować kod programu w miejscach gdzie łączy się z `MySQL`, albo wykomentować je. Nie wpłynie to na resztę testów. 

## Framework

Nasz program do testowania pustych pętli ma następującą strukturę katalogów:

```
├── config
│   └── list.txt
├── inc
│   ├── def.sql
│   ├── inc.bash
│   ├── inc.c
│   ├── inc.cpp
│   ├── inc.cs
│   ├── inc.f95
│   ├── inc.java
│   ├── inc.js
│   ├── inc.m.sh
│   ├── inc.p
│   ├── inc.perl
│   ├── inc.php
│   ├── inc.python
│   ├── inc.r
│   ├── inc.rb
│   ├── inc.sql.sh
│   └── inc.wl
├── util
│   └── text_to_sqlite.pl
├── log
│   ├── log.db
│   └── results.log
├── install.sh
├── analysis.nb
├── collect.sh
├── README.md
└── inc.bash
```

Katalog `config` zawiera listę parametrów dla których będziemy wykonywać serie testowe. Jest to zwykły plik tekstowy z liczbami całkowitymi w kolejnych liniach.

W `inc` znajduje się 16 plików odpowiadających za testowanie pętli oraz jeden do definiowania procedury w `MySQL`, która dopiero, kiedy zostanie wywołana wywołana będzie wykonywać pętle. 

W `util` umieściłem narzędzie pomocnicze, które pozwalało mi na przerzucanie danych z pliku tekstowego do bazy `SQLite`. Jest to z jednej strony związane z rozwijaniem tego softu. Pliki tekstowe były stosowane zanim przeszedłem na silnik bazodanowy. Z drugiej strony nie chciałem zaśmiecać bazy danymi pomiarowymi, których nie byłem pewien, więc jeśli istniało ryzyko, że na program będzie działał źle - na przykład kiedy spodziewałem się, że wyjdę poza zakres danego typu liczbowego - wyłączałem logowanie do bazy i posługiwałem się tylko plikiem. Jeśli wszystko było ok, mogłem bez problemu załączyć nowe wyniki do uzyskanych wcześniej.

Katalog `log` służy do przechowywania pliku tekstowego `results.log` oraz bazy danych `SQLite`, które powielają nazwę, liczbę pętli, czas, natomiast różnią się tym, że w bazie trzymany jest numer rewizji `gita`, a w pliku tekstowym: szybkość wykonywania obliczona jako iloraz ilości pętli i czasu.

Poza tym projekt zawiera: 

+ `install.sh` - skrypt instalacyjny (omówiłem go w poprzednim paragrafie), 
+ `inc.bash` - bazowy skrypt do robienia pojedynczego testu dla każdego języka, 
+ `collect.sh` - skrypt do wykonywania serii testów zgodnie z instrukcją podaną w `config/list.txt` 
+ i w końcu `analysis.nb` - notebook programu Mathematica. Służy on do dopasowywania modelu do danych pomiarowych i wygodnego generowania pliku `config/list.txt`.

Dzięki takiej strukturze jesteśmy w stanie bez problemu dodawać nowe języki programowania. Trzymanie w bazie numeru rewizji pozwala nam również sprawdzać, jak różne instrukcje spełniające teoretycznie tą samą funkcjonalność (np: `for` vs `while`) różnią się od siebie wydajnością. 

## Dataflow

Przepływ danych w programie posiada wbudowane sprzężenie zwrotne. Z jednej strony `inc.bash` testuje pętle za pomocą parametrów wyliczonych z modelu i czynników zawartych w `list.txt`, z drugiej strony, żeby móc dopasować model do danych, musieliśmy je najpierw dostać właśnie uruchamiając `inc.bash`.

Patrząc na wykres przepływu danych łatwo znajdziemy zamknięte koło, które mam na myśli.

![dataflow](http://i.imgur.com/hfjhnjY.png)

Jest to klasyczny problem, co było pierwsze, jajko czy kura? Pierwszy był model teoretyczny, który określił co warto mierzyć czy dane doświadczalne, dzięki którym możemy go zgadnąć? Tak jak w biologicznym odpowiedniku, tak tutaj odpowiedzią jest ewolucja. Początkowo każdy z programów `inc.i`, (gdzie `i` jest numerem testowanego języka programowania) był włączany ręcznie. Z jedną pętlą. Później z tysiącem, milionem, miliardem. Kiedy widziałem, że wykonuje się dłużej niż kilka sekund obniżałem liczbę pętli, kiedy krócej niż sekundę podnosiłem ją. Dążyłem do tego, żeby ręcznie znaleźć liczbę pętli odpowiadającą miej więcej 4-5 sekund wykonywania programu. Dzieliłem następnie tą liczbę przez 50 i otrzymana wartość stanowiła mój `parametr_i`. Dlaczego tak? Ponieważ dzięki temu dla czynnika równego 1 mogłem spodziewać się, że program wykonywać się będzie 0.08 do 0.10 sekundy. Nie było najmniejszego sensu schodzić do niższych czasów, bo wielkość mierzona czyli prędkość jest odwrotnie proporcjonalna do czasu, a więc błąd pomiarowy skaluje się z czasem jak `1/t^2`. Takie ręczne rozpoznawanie początkowej wielkości parametrów robiłem dla każdego języka. Dzięki temu uwspólniłem skalę dla wszystkich z wyjątkiem języka `Matlab`, którego inicjalizacja trwała 5 sekund z kawałkiem. Dla Matlaba robiłem oddzielną serię pomiarową zanim go wyczułem. Dane z tego typu testów trafiały do pliku `results.log`, ale o tym czy przenosić je do `log.db` decydowałem na podstawie wyczucia, w jednym przypadku zdarzyło się, że dla jednego z języków czasy rosły wraz z liczbą `$size` do pewnego momentu, a zaczęły trzymać się stałego poziomu. Okazało się, że zakresy zmiennych nie wystarczają do pomieszczenia liczby iteracji i jest ona bezczelnie rzutowana na mniejszą wartość. Były przypadki (python oraz r) gdzie brakowało pamięci RAM, bo pętla `for` zamiast inkrementować skalarny wskaźnik była skonstruowana tak, że ładowała do pamięci operacyjnej całą tablicę, po której później przebiegała. Ogólnie rzecz biorąc, nie dało by się zupełnie zautomatyzować testów na tym etapie. W niektórych językach trzeba było zmieniać typy, na przykład w pascalu zwykły `Int` nie wystarczył i trzeba było stosować `QWord`, analogicznie w `C#` typ `Int32` był zmieniany na `UInt64`. Podsumowując: model istniał tylko w mojej głowie. Na początku nie było `analysis.nb` ani `list.txt`, używanie `collect.sh` nie miało sensu bo ciekawiej było odpalać `inc.bash` zmieniając jedynie rząd wielkości czynnika na wejściu. 

Kiedy `results.log` rozrósł się, a ja zrozumiałem, że testowanie w stronę krótszych czasów jest nieopłacalne bo generuje za dużo błędu pomiarowego, a w stronę dłuższych czasów nieopłacalne, bo nie wnosi żadnych nowych efektów, wtedy powstał program `text_to_sqlite.pl` do konwertowania pliku tekstowego do postaci wierszy w bazie danych. Zrezygnowałem z zapisywania zmiennej `$speed` - szybkości pętli, jako, że dzięki silnikowi bazodanowemu jej wyliczanie było prostsze, uznałem natomiast, że jeśli wprowadzam zmiany w programach `inc.i`, to w danych może pojawić się bałagan. Żeby móc wykrywać dodałem zmienną `$git` z numerem rewizji. Wtedy powstał notebook `analysis.nb` i z jego pomocą wyliczyłem parametry do `bash.inc` z większą dokładnością. Zaplanowałem też serię pomiarową `list.txt` która wykładniczo rozrzedzała się dla rosnących czasów pomiarów. Dzięki modelowi mogłem wyliczyć ile czasu będzie trwał jaki pomiar. W ten sposób obieg danych zamknął się. Model zaczął wyznaczać optymalne punkty pomiarowe, a uzyskiwane dane zaczęły płynąć w coraz bardziej zautomatyzowany i zracjonalizowany sposób.

### Jądro programu

Kiedy wiemy już co jak działa i do czego służy obejrzymy kod programu `inc.bash`. Już od początku widzimy, że pisał to profesjonalista i nie mam tu na myśli siebie, tylko kolegę od którego dostałem ten kod :)

> inc.bash

```
#! /bin/bash

function onExit
{
	[ ! -z "$TMP" ] && \
	[   -d "$TMP" ] && \
	rm -Rf "$TMP";
	rm -f inc.class;
	exit;
}
```

Mam na myśli pierwsze trzy komendy w ciele funkcji `onExit`. Dokumentacja [basha](http://tldp.org/LDP/Bash-Beginners-Guide/html/sect_07_01.html) wyjaśnia, że lokalizacja wskazywana przez zmienną `$TMP` ma zostać usunięte jeśli zmienna `$TMP` coś w ogóle zawiera i jeśli wskazuje na katalog. Kolejna linia napisana przeze mnie to usunięcie pliku pochodzącego z kompilacji `javy`, który nie trafił do `$TMP` tylko dlatego, że nie potrafiłem go tam wrzucić. 

Funkcja `onExit` wykona się przy zamykaniu programu, co będzie zaznaczone później. Teraz przyjrzymy się funkcji `test` - kompletującej wszystkie dane, wykonującej testy i wysyłającej dane do bazy oraz pliku. Jest to centralny punkt całego systemu, odpowiada ona za uwspólnienie interfejsu wszystkich programów.

```
function test
{
	name="$1";
	size="$2";
	comm="${@:3}"
```

Przyjmuje ona na wejściu trzy lub więcej parametrów. Pierwszy to nazwa: zwykle `inc.<rozszerzenie języka>` np: `inc.c` lub `inc.js`. Nie jest ona w żaden sposób powiązana ani z lokalizacją pliku źródłowego, ani wykonywalnego. W zasadzie mogła by być dowolna. Przyjąłem jednak konwencję, że nazywa iśe tak jak plik źródłowy. Drugi parametr to liczba pętli jaka ma zostać wykonana `$size`, jest to iloczyn parametru skalującego i czynnika podawanego na wejściu do skryptu `inc.bash`. Kolejne parametry, niezależnie od ich ilości wrzucane są do zmiennej `$comm` - jest to komenda do włączenia programu, ale bez liczby pętli. 

```
	/usr/bin/time -o "$TMP/time" -f "%e" $comm $size &> /dev/null; #oryfinally %U instead %e
```

Po ustaleniu danych wejściowych wykonywany jest test. Z dokładnością do setnych sekundy mierzony jest czas wykonania komendy zapisanej w zmiennej `$comm` z parametrem `$size`. Wynik trafia do pliku tymczasowego w `$TMP/time`. Stamtąd do zmiennej `$time`

```
	time="$(cat "$TMP/time" 2> /dev/null)";
```

A następnie dzięki formatowaniu w `awk` na ekran konsoli. Jednocześnie to samo tylko bez przyjemnego dla człowieka formatowania, podzielone przecinkami trafia do pliku `log/results.log`

```
	echo $name $size $time |\
	awk '{printf "| %-12s | %16s | %8s s | %19.2f |\n", $1, $2, $3, $2/$3;}' \
	 | tee /dev/tty \
     | awk '{print $2","$4","$6","$9}' >> log/results.log
```

Ostatnia linia to zapis do bazy `SQLite`, który w zależności od ryzyka otrzymania złej jakości danych był wykomentowany. Uważny czytelnik zwróci tu uwagę na zmienną `$GIT`, która nie była nigdzie definiowana. Jest to zmienna globalna zawierająca numer rewizji, które pojawi się za chwilę.

```
     sqlite3 log/log.db  "insert into log (name,size,time,git) values ('$name',$size,$time,'$GIT');"
}
```

Logika skryptu jest dość przewidywalna. Zaczyn się od przejścia do katalogu gdzie zlokalizowany jest skrypt. Następnie ustawiamy coś w rodzaju nasłuchu na zdarzenia `SIGINT`, `SIGTERM ` i `EXIT`. Oznacza to, że jeśli będziemy chcieli wyłączyć program zanim skończy działać, to po sobie posprząta.

```
cd "$(dirname "${BASH_SOURCE[0]}")";
trap onExit SIGINT SIGTERM EXIT;

TMP="$(mktemp -d)";
POW=${1:-50};
GIT=`git rev-parse HEAD`;
```

Jeśli zastanawiasz się, co tu jest do sprzątania, to kolejna linijka stanowi odpowiedź na Twoje pytanie. Tworzymy w niej katalog tymczasowy do przechowywania skompilowanych wersji programów i wstawiamy jego lokalizację do zmiennej `$TMP`. Do `$POW` wstawiamy argument z jakim wywołaliśmy program `inc.bash` lub 50 jako wartość domyślną. Do zmiennej `$GIT` przyporządkowujemy numer aktualnej rewizji. Następne są kompilacje:

```
g++ -o "$TMP/cpp" 'inc/inc.cpp';
gcc -o "$TMP/c"   'inc/inc.c';
mcs -out:"$TMP/cs.exe" inc/inc.cs
javac 'inc/inc.java' -d .;
mysql -u root < inc/def.sql;
f95 -o "$TMP/f" inc/inc.f95
fpc -O2 inc/inc.p -o"$TMP/p" -Tlinux &>/dev/null
```

Języki dzielą się na kompilowalne i skryptowe. Tu mamy listę tych, które wymagają przygotowania. W przypadku `MySQL` jest to definiowanie procedury. W przypadku javy nie udało mi się jej pliku wykonywalnego włożyć do katalogu `$TMP`. Jeśli wiesz jak to zrobić, proszę napisz w komentarzu, lub daj link do jakiejś instrukcji. Z góry dzięki. Można by pomyśleć, kompilacje jak kompilacje, nic ciekawego, ale w ostatniej linijce - przy kompilacji Pascala - znajduje się flaga `-O2`, która sporo zmienia. Włącza ona analizator przepływu danych asemblera. On z kolei umożliwia procedurze eliminacji wspólnych pod-wyrażeń, na usunięcie niepotrzebnych przeładowań rejestru wartościami, które już zawierał. Więcej o falgach optymalizujących kompilację Pascala można przeczytać w [dokumentacji](http://www.math.uni-leipzig.de/pool/tuts/FreePascal/prog/node12.html).

Po procesie kompilacji (i definiowania procedury SQL) przechodzimy do wykonywania testów. Za ich wywoływanie odpowiada kod:

```
echo '+--------------+------------------+------------+---------------------+';
echo '|     File     |       Size       |    Time    |        Speed        |';
echo '+--------------+------------------+------------+---------------------+';
test    inc.m.sh    $[ 20000000*POW]    bash    inc/inc.m.sh; # long time of setup about 5 sec
test    inc.bash    $[    20598*POW]    bash    inc/inc.bash;
test    inc.sql.sh  $[    40713*POW]    bash    inc/inc.sql.sh;
test    inc.wl      $[   178362*POW]    MathematicaScript -script inc/inc.wl;
test    inc.cs      $[   500126*POW]    mono    "$TMP/cs.exe";
test    inc.js      $[   763305*POW]    node    inc/inc.js;
test    inc.python  $[  1441468*POW]    python  inc/inc.python;
test    inc.rb      $[  2484535*POW]    ruby    inc/inc.rb;
test    inc.perl    $[  2215594*POW]    perl    inc/inc.perl;
test    inc.r       $[   139211*POW]    Rscript inc/inc.r;
test    inc.php     $[ 10476892*POW]    php     inc/inc.php;
test    inc.f95     $[ 30079457*POW]    "/$TMP/f";
test    inc.cpp     $[ 36443924*POW]    "$TMP/cpp";
test    inc.c       $[ 37093252*POW]    "$TMP/c";
test    inc.p       $[253815805*POW]    "$TMP/p";
test    inc.java    $[255411892*POW]    java inc;
echo '+--------------+------------------+------------+---------------------+';
```

Echo wyświetla nagłówek i końcową linię tabeli. Natomiast instrukcje `test` wywołują funkcję zdefiniowaną kilka linijek wyżej. Wspominaliśmy już, że jej pierwszy parametr to nazwa, drugi liczba powtórzeń, a trzeci i kolejne to komenda wykonująca program. Część z nich wywołuje się przez interpreter jak `ruby` czy `php`, niektóre otwiera jak pliki binarne np: `fortran` i `c`, niektóre musiałem owinąć bashem, żeby mogły przyjąć parametr z linii komend (`sql` i `matlab`), są też rozwiązania hybrydowe, gdzie mimo kompilacji i tak używamy wirtualizacji za pomocą dedykowanego narzędzia jak `java`. 

Tajemnicze liczby w każdej linijce to parametry uzyskane z dopasowania modelu do danych. O sposobie w jaki je wybierałem wspominałem na początku tego paragrafu. Służą one do zapewnienia porównywalnego czasu wykonywania testów każdego z języków kiedy `inc.bash` jest sterowany tylko jedną liczbą zapisaną w `$POW`.

### Skrypty usprawniające przepływ danych

Z czasem zwiększania ilości danych i testowania nowych zakresów pojawiła się potrzeba automatyzacji dwóch procesów. Testowania całych serii czynników `$POW` oraz tymczasowego blokowania zapisu do bazy i w celu ludzkiej weryfikacji, czy dane są zgodne z modelem. Wykonywania pierwszego z tych zadań służy `collect.sh`

> collect.sh

```
#!/usr/bin/env bash

while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "POW = " $line;
    bash inc.bash $line
done < ${1:-config/list.txt}
```

Prosty skrypt czytający plik który mu podamy linia po linii (domyślnie `config/list.txt`), Wyświetla on te linie i przekazuje do `inc.bash`. Owszem powoduje to powtarzanie kompilacji za każdym razem, ale trwaja one tak krótko w porównaniu z testami, że to nie przeszkadza.

Drugi program przerzucający pliki tekstowe do bazy:

```
#!/usr/bin/perl -w
use warnings FATAL => 'all';
use DBI;
use strict;

my $db = DBI->connect("dbi:SQLite:log/log.db", "", "",{RaiseError => 1, AutoCommit => 1});
my $git='d1f050302c28aa8a837ec5453323df30cad9766e';
my $filename =  $ARGV[0] || 'log/results.log';
```

Po nagłówkach mamy tutaj zmienną `$db` przechowującą połączenie z bazą, `$git` zawierającą ręcznie wpisany numer rewizji i `$filename` pobierającą argument z linii komend z domyślą wartością ustawioną na lokalizację pliku z logami. Takie ustawienie zmiennych dawało elastyczność, a jednocześnie nie wymagało wpisywania parametrów w najbardziej powtarzalnych sytuacjach. Następnie program otwierał plik:

```
open( my $fh => $filename) || die "Cannot open $filename: $!";
```

i iterując po jego liniach zapisywał odpowiednio przekształcone rekordy do bazy:

```
while(my $line = <$fh>) {
        my @row = split(",",$line);
        $db->do("INSERT INTO log (name,size,time,git) values ('".$row[0]."',$row[1],$row[2],'$git');");
}
close($fh);
```

## Analiza

Zdarzało nam się na tym blogu analizować dane. Schemat jest prosty. Łączymy się z bazą. Wyciągamy dane do zmiennej, dopasowujemy model, rysujemy wykresy. Czasami wykres zachowuje się dziwnie, wtedy przyglądamy mu się uważniej. 

Aby połączyć się z bazą danych SQLite za pomocą programu `Mathematica` używamy komend:

```
Needs["DatabaseLink`"]
conn = OpenSQLConnection[
  JDBC["SQLite", ToString[NotebookDirectory[]] <> "/log/log.db"]]
```

Pierwsza z nich to importowanie paczki. Druga zapisuje do zmiennej `conn` nowe połączenie realizowane za pomocą interfejsu `JDBC`. Komenda `NotebookDirectory` zwraca lokalizację notebooka. `ToString` jak nazwa wskazuje zmienia ją w łańcuch znakowy, a znaki `<>` są operatorem konkatenacji stringów. W ten sposób `JDBC` przyjmuje tu tylko dwa argumenty: nazwę silnika bazodanowego i lokalizację pliku z bazą.

Pierwsze zapytanie do bazy będzie dotyczyło języków jakich używamy.

```
list = Flatten[
   SQLExecute[conn, "SELECT name FROM log GROUP BY name"]];
```

Za wykonanie zapytania na połączeniu `conn` odpowiada `SQLExecute`. Komenda `Flatten` służy spłaszczeniu tablicy, która w przeciwnym wypadku była by tablicą tablic. Jest to związane z tym, że jeśli wybieramy więcej niż jeden atrybut to tablica dwuwymiarowa jest bardziej naturalnym sposobem reprezentacji wyniku zapytania. Widać to dobrze na przykładzie kolejnego zapytania, które zadamy, a raczej całej serii zapytań:

```
data = Table[{i, 
    SQLExecute[conn, 
     "SELECT size,time FROM log WHERE name='" <> ToString[i] <> 
      "'"]}, {i, list}];
```

Tutaj do zmiennej `data` zapisujemy tablicę, która iterując po wyciągniętej wcześniej liście języków każdy swój element układa w dwuelementowa tablicę. Pierwszy z nich jest właśnie tą nazwą, drugi jest tablicą par zmiennych `size` i `time`, czyli liczb pętli i czasów wykonywania odpowiadających danemu językowi.

Kolejny "oneliner" odpowiada za modelowanie:

```
nlm = NonlinearModelFit[Log[data[[#, 2]]], 
     Log[Exp[a] Exp[x] + b^2], {a, b}, x] & /@ Range[list // Length];
```

Tak. Ta jedna linijka dopasowuje modele dla wszystkich języków za jednym razem. Rozłożymy ją na czynniki pierwsze.

Zacznijmy od najbardziej tajemniczych znaczków, czyli składni `f[#]&/@{1,2,3}` . Znaki `a/@b` oznaczają mapowanie, czyli zastosowanie operacji `a` do elementów pierwszego poziomu tablicy `b`. Znak `#` oznacza slot na włożenie danych, a `&` znacznikiem informującym, że to co nastąpi później będzie wkładane do slotów. Tak więc `f[#]&[a]` jest tym samym co `f[a]`. Ostatecznie `f[#]&/@{1,2,3}` jest równoważne `{f[1],f[2],f[3]}`. Wielkość `list//Length` to długość zmiennej `list`. W naszym przypadku `16`. Funkcja `Range` tworzy tablicę od jedności do swojego argumentu. Dlatego `Range[list//Length]` będzie tablicą od `1` do `16`. Więc te liczby kolejno będziemy wkładać do slotu oznaczonego `#` w wyrażeniu `NonlinearModelFit`. 

`NonlinearModelFit` jest funkcją języka `Mathematica` odpowiadającą za dopasowywanie modelu do danych, oraz zwracanie dodatkowych informacji związanych na przykład z błędami pomiarowymi. 

Jej pierwszym argumentem jest zbiór danych. W naszym przypadku zlogarytmowana lista par czasów i rozmiarów pętli. Działa tu zasada: "logarytm tablicy to tablica logarytmów". 

Drugi argument to model danych jaki dopasowujemy. U nas `Log[Exp[a] Exp[x] + b^2]`. Choć na pierwszy rzut oka nie wygląda, jest to prosta `Ax+B` tylko w zmienionym układzie współrzędnych. Spójrzmy na to tak. Do `x` i `y` dopasowywali byśmy prostą `y=Ax+B`, Jeśli zlogarytmujemy obie strony to mamy `log(y)=log(A exp(log(x))+B)`, dane, do jakich dopasowujemy to `{Log[x], Log[y]}`, więc tymczasowo nazywająć `log(x)=X` i `log(y)=Y` dostajemy wyrażenie `Y = log(A exp(X) + B)` dla danych `X,Y`. Jednak ponieważ nasze `A` jest bardzo małe, a `B` zawsze dodatnie, wprowadzamy oznaczenia `A=exp(a)` oraz `B=b^2`. Teraz `a` może mieć naturalne rzędy wielkości - tak lubiane przez metody numeryczne, a na `b` nie narzucamy żadnych ograniczeń dotyczących znaku - metody numeryczne skaczą ze szczęścia, kiedy widzą takie podstawienia. Od teraz będziemy operować zmiennymi `a` i `b` mając na myśli, że `A` i `B` możemy z nich łatwo obliczyć.

Trzeci argument `NonlinearModelFit` to lista stopni swobody, a czwarty nazwany po prostu `x` odpowiada naszemu dużemu `X` czyli logarytmowi z liczby powtórzeń pętli.

Mając dane i model możemy przełożyć je na interfejs zrozumiały dla człowieka, czyli wykresy. Za ich wyświetlenie odpowiada poniższy kod.
```
Do[Module[{img, bands},
  bands[x_] = nlm[[i]]["MeanPredictionBands", ConfidenceLevel -> .999];
  img = Show[{ListLogLogPlot[{data[[i, 2]]}, PlotRange -> Full, 
      PlotLabel -> data[[i, 1]], ImageSize -> 800, 
      BaseStyle -> {FontSize -> 15}, 
      FrameLabel -> {"$size [number of loops]", "$time [sec]"}, 
      Frame -> True, PlotStyle -> {Lighter[Red]}, 
      PlotLegends -> 
       Placed[SwatchLegend[{"Experimental data"}, 
         LegendMarkerSize -> {30, 30}], {0.3, 0.85}]], 
     LogLogPlot[{Exp[nlm[[i]][Log[x]]], Exp[bands[Log[x]]]}, {x, 1, 
       10^13}, PlotLegends -> 
       Placed[SwatchLegend[{nlm[[i]][
           "ParameterConfidenceIntervalTable"]}, 
         LegendMarkerSize -> {1, 1}], {0.3, 0.75}]]}];
  Print[img];
  Export["inc_" <> ToString[list[[i]]] <> ".png", img];
  ], {i, list // Length}]
```

Funkcja `Do` wykonuje swój pierwszy argument iterując po `i` od `1` do liczby badanych języków programowania. `Module` z jednej strony porządkuje kod zbierając go w jedną niepodzielną całość, z drugiej pozwala nie zaśmiecać głównego programu zmiennymi lokalnymi do przechowywania wykresów (`img`) i linii granicznych (`bands`). Owe linie graniczne to możliwie najkrótszy i najdłuższy czas wykonywania określonej ilości pętli przy założonym przedziale ufności. Nie wchodząc już w szczegóły, które związane głównie z formatowaniem nie są tak ciekawe: `img` zawiera wykres. Funkcja `Print` wyświetla go na ekranie a `Export` zapisuje do pliku. 

To wszystko. W 16 liniach zamknęliśmy całą analizę danych. Przy niektórych językach pojawią się pewne różnice w wynikach związane ze zmianami wprowadzanymi przy kolejnych commitach. Wymagane dla nich komendy będę podawał na bierząco.

## Wyniki



[![r.png](https://s27.postimg.org/jzgak8vab/image.png)](https://postimg.org/image/rffk61izj/)


+ `file` - plik i rozszerzenie języka
+ `size` - ilość kroków pętli
+ `time` - czas wykonywania programu
+ `speed` - ilość iteracji na sekundę



