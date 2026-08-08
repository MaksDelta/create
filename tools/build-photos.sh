#!/bin/bash
# Перебудовує photos.js з усіх зображень у папці photos/
# Використання:  ./tools/build-photos.sh
# Щоб додати нове фото — просто киньте його у photos/ і запустіть скрипт знову.

set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/photos"
TMP="$(mktemp -d)"
OUT="$ROOT/photos.js"

FULL_W=1200   # ширина картинки для експорту
THUMB_W=220   # ширина мініатюри для галереї
QUALITY=66

shopt -s nullglob nocaseglob
FILES=("$SRC"/*.jpg "$SRC"/*.jpeg "$SRC"/*.png "$SRC"/*.heic)
shopt -u nullglob nocaseglob

if [ ${#FILES[@]} -eq 0 ]; then
  echo "У папці $SRC немає зображень."; exit 1
fi

# Зберігаємо попередній photos.js, щоб перенести описи (desc) у новий файл.
PREV=""
if [ -f "$OUT" ]; then
  PREV="$TMP/prev.js"
  cp "$OUT" "$PREV"
fi

# Опис фото з попередньої збірки (шукаємо за іменем файлу). Порожньо, якщо не знайдено.
prev_desc() {
  [ -n "$PREV" ] || return 0
  grep -m1 -F "file: \"$1\"," "$PREV" \
    | sed -n 's/.*[,{] desc: "\(.*\)",[[:space:]]*$/\1/p'
}

{
  echo "/* ЗГЕНЕРОВАНО tools/build-photos.sh — картинки не редагуйте вручну."
  echo "   Щоб змінити набір фото: покладіть файли в photos/ і запустіть скрипт."
  echo "   Поле desc (опис фото) можна правити вручну — скрипт переносить його"
  echo "   у нову збірку за іменем файлу. */"
  echo "var PHOTOS = ["
} > "$OUT"

i=0
for f in "${FILES[@]}"; do
  i=$((i+1))
  base="$(basename "$f")"
  name="Фото $i"
  echo "  [$i/${#FILES[@]}] $base"

  sips -s format jpeg --resampleWidth $FULL_W -s formatOptions $QUALITY \
       --out "$TMP/full.jpg" "$f" >/dev/null 2>&1
  sips -s format jpeg --resampleWidth $THUMB_W -s formatOptions 60 \
       --out "$TMP/thumb.jpg" "$f" >/dev/null 2>&1

  W=$(sips -g pixelWidth  "$TMP/full.jpg" | tail -1 | awk '{print $2}')
  H=$(sips -g pixelHeight "$TMP/full.jpg" | tail -1 | awk '{print $2}')
  DESC="$(prev_desc "$base")"

  {
    printf '  { id: "p%d", name: "%s", file: "%s", w: %s, h: %s, desc: "%s",\n' "$i" "$name" "$base" "$W" "$H" "$DESC"
    printf '    thumb: "data:image/jpeg;base64,'
    base64 < "$TMP/thumb.jpg" | tr -d '\n'
    printf '",\n'
    printf '    src: "data:image/jpeg;base64,'
    base64 < "$TMP/full.jpg" | tr -d '\n'
    printf '" },\n'
  } >> "$OUT"
done

echo "];" >> "$OUT"
rm -rf "$TMP"
echo "Готово: $OUT ($(du -h "$OUT" | awk '{print $1}'), фото: $i)"
