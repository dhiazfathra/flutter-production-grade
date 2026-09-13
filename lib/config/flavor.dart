enum Flavor {
  dev,
  staging,
  prod;

  bool get isProduction => this == Flavor.prod;
}
