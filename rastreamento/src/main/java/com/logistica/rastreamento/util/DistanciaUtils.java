package com.logistica.rastreamento.util;

/**
 * Classe utilitária para cálculos geográficos.
 */
public final class DistanciaUtils {

    private static final double EARTH_RADIUS_KM = 6371.0;
    private static final double EARTH_RADIUS_METERS = 6371000.0;

    // Construtor privado para evitar instanciação
    private DistanciaUtils() {
        throw new UnsupportedOperationException("Classe utilitária não pode ser instanciada");
    }

    /**
     * Calcula a distância entre dois pontos geográficos em quilômetros.
     *
     * @param lat1 Latitude do primeiro ponto (em graus)
     * @param lon1 Longitude do primeiro ponto (em graus)
     * @param lat2 Latitude do segundo ponto (em graus)
     * @param lon2 Longitude do segundo ponto (em graus)
     * @return Distância em quilômetros
     */
    public static double calculateDistanceInKm(double lat1, double lon1, double lat2, double lon2) {
        return calculateDistance(lat1, lon1, lat2, lon2, EARTH_RADIUS_KM);
    }

    /**
     * Calcula a distância entre dois pontos geográficos em metros.
     *
     * @param lat1 Latitude do primeiro ponto (em graus)
     * @param lon1 Longitude do primeiro ponto (em graus)
     * @param lat2 Latitude do segundo ponto (em graus)
     * @param lon2 Longitude do segundo ponto (em graus)
     * @return Distância em metros
     */
    public static double calculateDistanceInMeters(double lat1, double lon1, double lat2, double lon2) {
        return calculateDistance(lat1, lon1, lat2, lon2, EARTH_RADIUS_METERS);
    }

    private static double calculateDistance(double lat1, double lon1, double lat2, double lon2, double radius) {
        // Converter graus para radianos
        double lat1Rad = Math.toRadians(lat1);
        double lon1Rad = Math.toRadians(lon1);
        double lat2Rad = Math.toRadians(lat2);
        double lon2Rad = Math.toRadians(lon2);

        // Diferenças entre as coordenadas
        double dLat = lat2Rad - lat1Rad;
        double dLon = lon2Rad - lon1Rad;

        // Fórmula de Haversine
        double a = Math.pow(Math.sin(dLat / 2), 2) +
                Math.cos(lat1Rad) * Math.cos(lat2Rad) *
                        Math.pow(Math.sin(dLon / 2), 2);

        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        return radius * c;
    }
}