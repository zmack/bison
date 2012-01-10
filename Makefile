
calc: calc.l calc.y
	bison -o calc.tab.c -d calc.y
	flex -o calc.yy.c calc.l
	cc -o $@ calc.tab.c calc.yy.c -lfl

clean:
	rm calc calc.tab.c calc.yy.c
