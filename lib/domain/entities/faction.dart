enum Faction { star, moon }

extension FactionX on Faction {
  Faction get opponent => this == Faction.star ? Faction.moon : Faction.star;
  String  get iconAsset => this == Faction.star
      ? 'assets/images/ui/star.svg'
      : 'assets/images/ui/moon.svg';
}