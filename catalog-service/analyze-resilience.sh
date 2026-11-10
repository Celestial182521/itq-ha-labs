#!/bin/bash
if [ ! -f "availability-baseline.txt" ] || [ ! -f "resilience-sample.txt" ]; then
    echo "Faltan availability-baseline.txt o resilience-sample.txt"; exit 1
fi
echo ""
echo "===== ANÁLISIS DE RESILIENCIA: Lab 1.1 vs Lab 1.2 ====="
echo ""
echo "LÍNEA BASE (Lab 1.1 - SIN patrones)"
TOTAL_1_1=$(wc -l < availability-baseline.txt)
SUCCESS_1_1=$(grep -c '"status":"SUCCESS"' availability-baseline.txt || true)
ERRORS_1_1=$((TOTAL_1_1 - SUCCESS_1_1))
AVAIL_1_1=$(awk "BEGIN {printf \"%.4f\", $SUCCESS_1_1 / $TOTAL_1_1}")
echo "Total solicitudes:         $TOTAL_1_1"
echo "SUCCESS (HTTP 200):        $SUCCESS_1_1"
echo "Errores HTTP 500:          $ERRORS_1_1"
echo "Disponibilidad:            $AVAIL_1_1"
echo ""
echo "CON PATRONES (Lab 1.2 - Timeout + Retry + Fallback + CircuitBreaker)"
TOTAL_1_2=$(wc -l < resilience-sample.txt)
SUCCESS_1_2=$(grep -c '"status":"SUCCESS"' resilience-sample.txt || true)
DEGRADED_1_2=$(grep -c '"status":"DEGRADED_CACHE"' resilience-sample.txt || true)
OK_1_2=$((SUCCESS_1_2 + DEGRADED_1_2))
AVAIL_1_2=$(awk "BEGIN {printf \"%.4f\", $OK_1_2 / $TOTAL_1_2}")
echo "Total solicitudes:         $TOTAL_1_2"
echo "SUCCESS (HTTP 200):        $SUCCESS_1_2"
echo "DEGRADED_CACHE (HTTP 200): $DEGRADED_1_2"
echo "Errores HTTP 500:          $(grep -cE '^[0-9]+ 500 ' resilience-sample.txt || true)"
echo "Otros errores (timeout):   $(grep -cE '^[0-9]+ 000 ' resilience-sample.txt || true)"
echo "Disponibilidad:            $AVAIL_1_2"
echo ""
echo "LATENCIA"
echo "Máx. Lab 1.1:              $(awk '{print $3}' availability-baseline.txt | sort -n | tail -1) s"
echo "Máx. Lab 1.2:              $(awk '{print $3}' resilience-sample.txt | sort -n | tail -1) s"
echo "Promedio Lab 1.1:          $(awk '{s+=$3} END {printf "%.3f", s/NR}' availability-baseline.txt) s"
echo "Promedio Lab 1.2:          $(awk '{s+=$3} END {printf "%.3f", s/NR}' resilience-sample.txt) s"
echo "Lentas (>2.5s) Lab 1.1:    $(awk '$3 > 2.5' availability-baseline.txt | wc -l)"
echo "Lentas (>2.5s) Lab 1.2:    $(awk '$3 > 2.5' resilience-sample.txt | wc -l)"
echo ""
echo "MEJORA"
echo "Disponibilidad mejorada:   $(awk "BEGIN {printf \"%.4f\", $AVAIL_1_2 - $AVAIL_1_1}")"
echo "Salvadas por @Fallback:    $DEGRADED_1_2"
echo ""
