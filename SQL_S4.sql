
/* ============================================================
   CASO 1: LISTADO DE TRABAJADORES
   Se muestran trabajadores con sueldo entre $650.000 y $3.000.000.
   Orden: ciudad descendente y sueldo ascendente.
   ============================================================ */
SELECT UPPER(t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno)
           AS "Nombre Completo Trabajador",
       TO_CHAR(t.numrut, 'FM99G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')
           || '-' || t.dvrut AS "RUT Trabajador",
       UPPER(NVL(tt.desc_categoria, 'SIN TIPO')) AS "Tipo Trabajador",
       UPPER(NVL(cc.nombre_ciudad, 'SIN CIUDAD')) AS "Ciudad Trabajador",
       '$' || TO_CHAR(t.sueldo_base, 'FM9G999G999',
                      'NLS_NUMERIC_CHARACTERS='',.''') AS "Sueldo Base"
FROM trabajador t
INNER JOIN tipo_trabajador tt
        ON t.id_categoria_t = tt.id_categoria
INNER JOIN comuna_ciudad cc
        ON t.id_ciudad = cc.id_ciudad
WHERE t.sueldo_base BETWEEN 650000 AND 3000000
ORDER BY UPPER(cc.nombre_ciudad) DESC, t.sueldo_base ASC;

/* ============================================================
   CASO 2: LISTADO DE CAJEROS
   Se cuentan tickets, suman ventas y suman comisiones.
   Solo cajeros con ventas totales superiores a $50.000.
   ============================================================ */
SELECT TO_CHAR(t.numrut, 'FM99G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')
           || '-' || t.dvrut AS "RUT Trabajador",
       INITCAP(t.nombre) || ' ' || UPPER(t.appaterno) AS "Nombre Trabajador",
       COUNT(tc.nro_ticket) AS "Total Tickets",
       '$' || TO_CHAR(SUM(tc.monto_ticket), 'FM9G999G999G999',
                      'NLS_NUMERIC_CHARACTERS='',.''') AS "Total Vendido",
       '$' || TO_CHAR(SUM(NVL(ct.valor_comision, 0)), 'FM9G999G999G999',
                      'NLS_NUMERIC_CHARACTERS='',.''') AS "Comisión Total",
       UPPER(tt.desc_categoria) AS "Tipo Trabajador",
       UPPER(cc.nombre_ciudad) AS "Ciudad Trabajador"
FROM trabajador t
INNER JOIN tipo_trabajador tt
        ON t.id_categoria_t = tt.id_categoria
INNER JOIN comuna_ciudad cc
        ON t.id_ciudad = cc.id_ciudad
INNER JOIN tickets_concierto tc
        ON t.numrut = tc.numrut_t
LEFT JOIN comisiones_ticket ct
       ON tc.nro_ticket = ct.nro_ticket
WHERE UPPER(tt.desc_categoria) = 'CAJERO'
GROUP BY t.numrut, t.dvrut, t.nombre, t.appaterno,
         tt.desc_categoria, cc.nombre_ciudad
HAVING SUM(tc.monto_ticket) > 50000
ORDER BY SUM(tc.monto_ticket) DESC;

/* ============================================================
   CASO 3: LISTADO DE BONIFICACIONES
   Bono Fonasa: 1% del sueldo; otros sistemas: $0.
   Bono antiguedad: hasta 10 anios, 10%; 11 o mas, 15%.
   Se considera el estado civil vigente al ejecutar el reporte.
   ============================================================ */
SELECT TO_CHAR(t.numrut, 'FM99G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')
           || '-' || t.dvrut AS "RUT Trabajador",
       INITCAP(t.nombre || ' ' || t.appaterno) AS "Trabajador Nombre",
       EXTRACT(YEAR FROM t.fecing) AS "Año Ingreso",
       EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM t.fecing)
           AS "Años Antigüedad",
       COUNT(DISTINCT af.numrut_carga) AS "Num. Cargas Familiares",
       INITCAP(i.nombre_isapre) AS "Nombre Isapre",
       '$' || TO_CHAR(t.sueldo_base, 'FM9G999G999',
                      'NLS_NUMERIC_CHARACTERS='',.''') AS "Sueldo Base",
       '$' || TO_CHAR(
             ROUND(CASE WHEN UPPER(i.nombre_isapre) = 'FONASA'
                        THEN t.sueldo_base * 0.01
                        ELSE 0 END),
             'FM9G999G999', 'NLS_NUMERIC_CHARACTERS='',.''') AS "Bono Fonasa",
       '$' || TO_CHAR(
             ROUND(CASE WHEN EXTRACT(YEAR FROM SYSDATE)
                                   - EXTRACT(YEAR FROM t.fecing) <= 10
                        THEN t.sueldo_base * 0.10
                        ELSE t.sueldo_base * 0.15 END),
             'FM9G999G999', 'NLS_NUMERIC_CHARACTERS='',.''') AS "Bono Antigüedad",
       INITCAP(a.nombre_afp) AS "Nombre AFP",
       UPPER(ec.desc_estcivil) AS "Estado Civil"
FROM trabajador t
INNER JOIN isapre i
        ON t.cod_isapre = i.cod_isapre
INNER JOIN afp a
        ON t.cod_afp = a.cod_afp
INNER JOIN est_civil e
        ON t.numrut = e.numrut_t
INNER JOIN estado_civil ec
        ON e.id_estcivil_est = ec.id_estcivil
LEFT JOIN asignacion_familiar af
       ON t.numrut = af.numrut_t
WHERE e.fecter_estcivil IS NULL
   OR e.fecter_estcivil > SYSDATE
GROUP BY t.numrut, t.dvrut, t.nombre, t.appaterno,
         t.fecing, t.sueldo_base, i.nombre_isapre,
         a.nombre_afp, ec.desc_estcivil
ORDER BY t.numrut ASC;