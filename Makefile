
calc: calc.l calc.y
	bison -o calc.tab.c -d calc.y
	flex -o calc.yy.c calc.l
	cc -o bin/$@ calc.tab.c calc.yy.c -lfl

wc: wc.l
	flex -o wc.yy.c wc.l
	cc -o bin/$@ wc.yy.c

includer: includer.l
	flex -o includer.yy.c includer.l
	cc -o bin/$@ includer.yy.c

conc: conc.l
	flex -o conc.yy.c conc.l
	cc -o bin/$@ conc.yy.c

all: calc wc includer conc

clean:
	rm bin/* *.yy.c *.tab.c
