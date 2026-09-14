-- Migración: plazo de pago elegible + interés y total a pagar en creditos
-- Contexto: antes el plazo (dias_totales) se calculaba solo según el monto.
-- Ahora el usuario elige el plazo (7 / 10 / 15 / 30 días) en la pantalla
-- "Solicitar crédito", y se aplica un interés fijo del 10% que se muestra
-- en el resumen de la solicitud.

alter table creditos
  add column if not exists interes numeric,
  add column if not exists total_a_pagar numeric;

-- Backfill de créditos ya existentes (interés 10% sobre el monto original,
-- consistente con la nueva regla de negocio).
update creditos
set
  interes = round(monto * 0.10, 2),
  total_a_pagar = round(monto * 1.10, 2)
where interes is null;

-- A partir de aquí, saldo_pendiente para créditos NUEVOS representa el
-- total a pagar (monto + interés), no solo el monto solicitado.
