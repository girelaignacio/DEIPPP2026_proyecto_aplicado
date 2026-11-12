****************************************
******      2.DATA PROCESSING     ******
****************************************


/*
En este script llevamos a cabo un preprocesamiento de la base de datos. El objetivo final es construir una nueva base de datos con la variable de resultado. Para ello primero necesitamos también reconstruir la base de datos. En las comunidades hay variaciones de mayúsculas/minúsculas así como errores de ortografía. 
*/


clear all
log using processing.log, replace // guardamos la salida en un archivo .log

*** Working directory path 
global path_home "C:\Users\girel\Dropbox\Doctorado\Impact Evaluation\JPAL\Proyecto" 
global path_out "$path_home\out_data"
global path_ado "$path_home\ado"


*** Leemos la base de datos en 1.save_dta.do
use "$path_home/base.dta", clear 

/*

2.1 Creación de nuevas variables de interés

*/

*** Creamos una nueva variable id_cluster
clonevar id = ID_anon
lab var id "individual id"
duplicates report ID_anon // chequeamos si hay duplicados

*** Limpiamos la variable comunidad
* Creamos una varibale cluster codificada con las etiquetas de cada comunidad
gen str50 comunidad_clean = strtrim(itrim(Comunidad))

* Estandarizamos variaciones de mayúsculas/minúsculas y faltas de ortografía a un nombre base oficial:
replace comunidad_clean = "Batzacon" if inlist(comunidad_clean, "BATZACON", "Batzacon", "Bazacon","Balzacon")
replace comunidad_clean = "Balsayan" if comunidad_clean == "Balsayan"
replace comunidad_clean = "Calshi" if inlist(comunidad_clean, "CALSHI", "Calshi")
replace comunidad_clean = "Cadeate" if comunidad_clean == "Cadeate"
replace comunidad_clean = "Cuatro esquinas" if comunidad_clean == "Cuatro esquinas"
replace comunidad_clean = "Curía" if comunidad_clean == "Curia"
replace comunidad_clean = "Dos Mangas" if inlist(comunidad_clean, "Dos Mangas", "Dos mangas")
replace comunidad_clean = "La Esperanza" if inlist(comunidad_clean, "La Esperanza", "La esperanza")
replace comunidad_clean = "La Silveria" if inlist(comunidad_clean,"La Silveria", "Silveria")
replace comunidad_clean = "Laturun" if inlist(comunidad_clean, "Latarun", "Laturum", "Laturun")
replace comunidad_clean = "Libertador Bolívar" if inlist(comunidad_clean, "Libertador Bolibar", "Libertador Bolivar", "Libertador Bolívar", "Libertador boliviar", "Libertador bolívar")
replace comunidad_clean = "Miraflores" if comunidad_clean == "Miraflores"
replace comunidad_clean = "Montañita" if comunidad_clean == "Montañita"
replace comunidad_clean = "Pulingui" if inlist(comunidad_clean, "PULINGUI", "Pulingui", "Pulingüi", "Pulingui San Pablo", "Pulingui San pablo")
replace comunidad_clean = "Pajiza" if inlist(comunidad_clean,"Pajiza", "Pajillales")
replace comunidad_clean = "Paquibug San Gerardo" if inlist(comunidad_clean, "Paquibug San Gerardo", "Paquibug San gerardo", "paquibug San gerardo")
replace comunidad_clean = "Paquibug San Pablo" if inlist(comunidad_clean, "Paquibug San Pablo", "Paquibug San pablo")
replace comunidad_clean = "Punguiño" if comunidad_clean == "Punguiño"
replace comunidad_clean = "Sigsipamba" if inlist(comunidad_clean, "SIGSIPAMBA", "Sigsibamba", "Sigsipamba")
replace comunidad_clean = "San José" if inlist(comunidad_clean, "San  José", "San Jose", "San José", "Sn Antonio")
replace comunidad_clean = "San Andrés Barrio Santa Rosa" if comunidad_clean == "San Andrés Barrio Santa Rosa"
replace comunidad_clean = "San Antonio" if inlist(comunidad_clean, "San Antonio", "Sn Antonio")
replace comunidad_clean = "San Pablo" if comunidad_clean == "San Pablo"
replace comunidad_clean = "San Pedro" if comunidad_clean == "San Pedro"
replace comunidad_clean = "Sanjapamba" if comunidad_clean == "Sanjapamba"
replace comunidad_clean = "Santa Lucia" if comunidad_clean == "Santa Lucia"
replace comunidad_clean = "Santa Rosa" if comunidad_clean == "Santa Rosa"
replace comunidad_clean = "Sinchal" if inlist(comunidad_clean, "Sincha", "Sinchal", "Sinchali")
replace comunidad_clean = "Singla" if comunidad_clean == "Singla"
replace comunidad_clean = "Sonchale" if comunidad_clean == "Sonchale"
replace comunidad_clean = "Tulun" if comunidad_clean == "Tulun"
replace comunidad_clean = "Tunsalao" if comunidad_clean == "Tunsalao"

* codificamos la variable original creando la variable 'comunidad'
encode comunidad_clean, gen(comunidad) 
tab comunidad, m  // verificamos la nueva codificación
codebook comunidad

*** Limpiamos la variable Parroquiademuestra
* parecido al caso de las comunidades
gen parroquia_str = strtrim(itrim(Parroquiademuestra))
* codificamos la variable original creando la variable 'parroquia'
encode parroquia_str, gen(parroquia)
tab parroquia, m  // verificamos la nueva codificación
codebook parroquia
		
*** Variable: genero ***
gen genero = 1 if Cuáleselsexodelniñoon == "Masculino"
replace genero = 2 if Cuáleselsexodelniñoon == "Femenino"
* creamos la etiqueta de valores
label define sex_lbl 1 "Masculino" 2 "Femenino"
* asignamos la etiqueta a la nueva variable numérica
label values genero sex_lbl
* Chequeamos
tab genero, m
codebook genero

*** Variable: edad_meses
gen edad_meses = Edaddelniñoaenmeses
* Chequeamos si es numérica
desc edad_meses
tab edad_meses, m  		// 5 observacioes faltantes
gen  str6 ageunit = "months" 
lab var ageunit "months"

sum edad_meses


/*

2.2 Creación de la variable resultado

*/

* Variable: weight *** (en kg)
clonevar weight = Pesoactualenkg
codebook weight, tab(9999)	// chequeamos si hay valores fuera del rango
sum weight 				
* hay dos observaciones: 1 con 88,0999 y 1 con 2350 -> reemplazamos con missing
replace weight = . if weight > 40 // eliminamos si pesa mas de 40kg 

* Variable: height *** (en cm)
clonevar height = Tallaactualcm
codebook height, tab(9999)	// chequeamos si hay valores fuera del rango
sum height 
* hay una observacion con 5,9 -> reemplazamos con missing 	
replace height = . if height < 25

* Variable: measure	
gen measure = " "	//no se sabe cómo se midieron los niños/as
tab measure

* Variable: oedema 
gen  oedema = "n"  

* Variable: sampling weight
gen  sw = 1	

* Compute z-score
adopath + "$path_ado/igrowup_stata"

gen str100 reflib = "$path_ado/igrowup_stata"
lab var reflib "Directory of reference tables"

gen str100 datalib = "$path_out" 
lab var datalib "Directory for datafiles"

* Nombre del archivo de salida que generará la OMS
gen str30 datalab = "children_nutri" 
lab var datalab "Working file"

* Creamos nuevas variable para utilizar en el comando igrowup
clonevar gender = genero
clonevar age_ch_months = edad_meses

igrowup_restricted reflib datalib datalab gender age_ch_months ageunit weight height measure oedema sw

use "$path_out/children_nutri_z_rc.dta", clear 

/*  
Se crearon nuevas variables:
_zwei: Z-score de Peso para la Edad (bajo peso).

_zlen: Z-score de Talla para la Edad (desnutrición crónica / retraso en el crecimiento).

_zwfl: Z-score de Peso para la Talla (desnutrición aguda).

_zbmi: Z-score de Índice de Masa Corporal para la Edad.
*/

gen haz = _zlen
tab _flen, m                      // cuántos fueron marcados como implausibles
count if missing(haz)

* Muestra de referencia: menores de 24 meses con HAZ válido
keep if age_ch_months < 24 & !missing(haz)     // sensibilidad: <= 24
* Reemplazar valores implausibles según la convención OMS
replace haz = . if _flen == 1   // o reemplazar si haz < -6 | haz > 6
count
* Creamos un límite superior más estricto que el inferior: un HAZ de -4 o -5
* es plausible en desnutrición severa, uno de +4 en esta población no.
local tope_sup =  4
local tope_inf = -5

gen outlier = (haz > `tope_sup' | haz < `tope_inf') if !missing(haz)
tab outlier,m

replace haz = . if outlier == 1


/*

2.3 Guardamos la base de datos con las varibales de interés

*/

keep id comunidad parroquia genero edad_meses haz 

save data.dta, replace

log close
exit
