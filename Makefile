
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

calc-2:
	bison -o calc-2.tab.h calc-2.y
	flex -o calc-2.yy.c calc-2.l
	cc -o bin/$@ calc-2.yy.c calc-2.c -lfl

supercalc:
	bison -v -o supercalc.tab.h supercalc.y
	flex -o supercalc.yy.c supercalc.l
	cc -o bin/$@ supercalc.yy.c supercalc.c -lfl

all: calc wc includer conc

clean:
	rm bin/* *.yy.c *.tab.c
