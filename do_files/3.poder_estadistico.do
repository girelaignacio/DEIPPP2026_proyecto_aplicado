****************************************
******    3.PODER ESTADÍSTIC0     ******
****************************************

/*
En este script llevamos a cabo un análisis del poder estadístico. Debido a la 
potencial presencia de externalidades, subiremos el nivel de aleatorización por comunidades
y, además, estratificaremos por parroquias. 
*/


clear all
log using poder_estadistico.log, replace // guardamos la salida en un archivo .log

*** Working directory path 
global path_home "C:\Users\girel\Dropbox\Doctorado\Impact Evaluation\JPAL\Proyecto" 
global path_out "$path_home\out_data"

*** Leemos la base de datos en 1.save_dta.do
use "$path_home/data.dta", clear 

*** Hacemos un rápido análisis de la distribución de la variable resultado (haz)
bysort parroquia: sum haz
sum haz

/*

3.1 Aleatorización y estratificación

*/

set seed 1234 // inicializamos una semilla
gen random = runiform() // generamos una variable uniforme (entre 0 y 1)

* Nos quedamos a nivel de comunidad (conglomerado) asegurando conservar la variable de parroquia
preserve
collapse (first) parroquia, by(comunidad) // 

gen rand = runiform() // generamos un número aleatorio por comunidad

* Ordenamos por parroquia y por el número aleatorio dentro de cada una
bysort parroquia (rand): gen orden = _n
bysort parroquia (rand): gen total_comunidades = _N

* Asignamos tratamiento a la mitad inferior de las comunidades ordenadas aleatoriamente en cada parroquia.
gen treat = (orden <= ceil(total_comunidades / 2))

keep comunidad treat parroquia // guardamos sólo la asignación a nivel de comunidad
tempfile asignacion_tratamiento
save `asignacion_tratamiento'
restore

* Ahora mergeamos la asignación de vuelta a la base original de niños
merge m:1 comunidad using `asignacion_tratamiento'
drop _merge random 

* Chequeamos el balance por parroquia y a nivel general
replace treat = . if haz ==. // reemplazamos por missing si haz es missing
tab parroquia treat, col
tab treat, m

/*

3.2 Estudiamos balance de la aleatorización en variables de interés

*/
preserve
* Chequeamos el balance por grupo de edad. Creamos una variable tal. 
gen edad_gr = 1 if edad_meses < 6
replace edad_gr = 2 if inrange(edad_meses, 6, 11)
replace edad_gr = 3 if inrange(edad_meses, 12, 17)
replace edad_gr = 4 if inrange(edad_meses, 18, 23)
label define edad_gr 1 "0-5" 2 "6-11" 3 "12-17" 4 "18-23"
label values edad_gr edad_gr
tabstat haz, by(edad_gr) stat(n mean sd) // Vemos que a partir de los 6 meses es donde se nota un quiebre en la distribución
tab edad_gr, gen(d_edad)
regress d_edad1 treat i.parroquia, cluster(comunidad)
regress d_edad2 treat i.parroquia, cluster(comunidad)
regress d_edad3 treat i.parroquia, cluster(comunidad)
regress d_edad4 treat i.parroquia, cluster(comunidad)
* Todas las regresiones muestran un p-value > 0.05.


* Chequamos el balance por proporción de desnutridos en cada comunidad
gen stunting = (haz < -2) // generamos la variable: desnutrido crónico si se aleja dos desviaciones estándar de la media
tabstat stunting, by(parroquia) stat(n mean)

collapse (mean) prop_stunting = stunting prop_edad1 = d_edad1 (count) n_niños = haz, by(comunidad treat parroquia)
regress prop_stunting treat i.parroquia
restore

* Chequeamos por genero
regress genero treat i.parroquia, cluster(comunidad)

/*

3.3 Calcuamos la correlación entre las comunidades (ICC)

*/
loneway haz comunidad
local rho = r(rho) // el ICC no es significativo

/*

3.4 Calculamos el poder estadístico

*/

*** Obtenemos las variables importantes de interés
sum haz
local mu = r(mean)
local sd = r(sd)
sum haz if treat == 0
local sd_control = r(sd)
sum haz if treat == 1
local sd_treat = r(sd)

*** Calculamos el EMD para nuestros datos (tamaños de muestra) y poder estadístico mínimo deseable
* Vemos un escenario de aleatorización individual (159 niños/as perfectamente balanceados)
power twomeans `mu', alpha(0.05) n(153) power(0.8) sd(`sd')
local emd = r(delta)


* Marcamos una observación por cada comunidad única
bysort comunidad: gen tag_comunidad = (_n == 1)

* Contar cuántas comunidades hay en Control (0) y Tratamiento (1)
tab treat if tag_comunidad == 1
count if tag_comunidad == 1 & treat == 0 // 14 Comunidades en Control

count if tag_comunidad == 1 & treat == 1 // 14 Comunidades en Tratamiento


* Calcular el número promedio de niños por comunidad (m1 y m2)
preserve
	* Contamos niños por comunidad
	contract comunidad treat, freq(n_ninos)
	
	* Sacamos el promedio de niños en control y tratamiento
	summarize n_ninos if treat == 0
	local m1 = r(mean)
	
	summarize n_ninos if treat == 1
	local m2 = r(mean)
restore

* Verificamos los valores guardados
display "K1 (Control) = 14, m1 = `m1'"
display "K2 (Treat)   = 14, m2 = `m2'"

* Ahora hacemos el cálculo considerando estructura de conglomerados:
power twomeans `mu', k1(14) k2(14) m1(`m1') m2(`m2') rho(0 `rho') sd(`sd') alpha(0.05) power(0.8)

/*

3.5 ¿Qué pasaría si...

*/

/* 
En los cálculos anteriores vemos las claras limitaciones de la muestra disponible. 
Podríamos recomendar al programa extender la muestra a todas las comunidades. Además,
plantea que hay otras dos parroquias con comunidades que podríamos incluir. Por lo tanto, 
vamos a calcular el EMD incluyendo todas esas comunidades. Esto implica asumir que:
- la media y desviación estándar no cambia (utilizaremos el de la línea de base)
- el número de niños promedio por comunidad en los grupos de control y tratamiento
- la correlacción intraclase (ICC) permanece igual, analizamos la sensibilidad con otros ICC=0.05, 0.1.
*/

*** EMD
* 50 y 50 entre todas las comunidades de las parroquias de San Andrés y Marglaralto
power twomeans `mu', k1(26) k2(27) m1(`m1') m2(`m2') rho(0 0.01 0.05 0.1 0.2) sd(`sd') alpha(0.05) power(0.8)

* Ahora qué pasaría si incluimos las comunidades de las otras dos parroquias?
* 50 y 50 entre las comunidades de las parroquias de San Andrés y Marglaralto
power twomeans `mu', k1(55) k2(55) m1(`m1') m2(`m2') rho(0 0.01 0.05 0.1 0.2) sd(`sd') alpha(0.05) power(0.8) 
local emd = r(delta)

*** Tamaño de muestra
* En lugar de fijar K y pedir m, fijamos m = 5 y le pedimos a Stata el número de comunidades K necesarias:
power twomeans `mu', m1(`m1') m2(`m2') rho(0 0.01 0.05 0.1 0.2) sd(`sd') alpha(0.05) power(0.8) diff(0.10(0.05)0.50) 




log close
exit

