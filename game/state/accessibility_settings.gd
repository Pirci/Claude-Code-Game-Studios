class_name AccessibilitySettings
extends RefCounted
## Erişilebilirlik tercihleri (art bible §7 "Erişilebilirlik Ayarları"). Mantık yok, sadece veri.
##
## RootContext oturum boyunca tek örnek tutar; ayarlar ekranı yazar, oyun bağlamı okur.
## Kalıcılık henüz yok (diğer ayarlar gibi) — Save/Load ADR'ı (C-16) ile gelecek.


## Tamgalar her bölgede görünür + sahipli bölgelere ek 1px iç kontur.
var color_blind_mode: bool = false
## Animasyonlar durur / anında tamamlanır, UI geçişleri düz kesme. Şu an oyunda
## animasyon yok; Erlik lekesi, Kök Böri ve geçiş animasyonları eklenirken okunmalı.
var reduce_motion: bool = false
## Haritada bölge adı etiketleri (ordu sayısı her zaman görünür).
var show_region_names: bool = true
