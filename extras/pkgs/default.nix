# Kendi paketledigimiz seyler (overlay).
# Yeni paket ekleme: klasor ac + derivation yaz + asagiya 1 satir ekle,
# sonra her yerde pkgs.<isim> olarak kullan.
final: prev: {
  datfetch = final.callPackage ./datfetch/package.nix { };
}
