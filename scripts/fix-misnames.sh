#!/usr/bin/env bash
# Resolve misnamed/duplicate book files in /volume2/Library/books.
#
# For each misnamed file we either:
#   - DELETE (if a correctly-named copy of the actual content already exists)
#   - RENAME (if it's the only copy of its real content)
#
# Categorisation derived from the EPUB-metadata audit. The script verifies the
# expected "real" file exists before deleting; if not, it skips and warns.
#
# Default: DRY RUN. Pass --execute to actually move/delete.
set -u
if [ -f "$HOME/.ssh/load-vault-keys.sh" ]; then source "$HOME/.ssh/load-vault-keys.sh"; fi
NAS="bobbi@192.168.1.165"
EXECUTE="false"
[ "${1:-}" = "--execute" ] && EXECUTE="true"
echo "Mode: $([ "$EXECUTE" = "true" ] && echo EXECUTE || echo DRY-RUN)"
echo

ssh -o BatchMode=yes -o StrictHostKeyChecking=no "$NAS" \
     "EXECUTE=$EXECUTE bash -s" <<'REMOTE'
set +e
B=/volume2/Library/books

if [ "$EXECUTE" = "true" ]; then
    DEL() { rm -f "$1" && echo "DELETED: $1"; }
    DEL_DIR() { rm -rf "$1" && echo "DELETED-DIR: $1"; }
    RENAME() { mv "$1" "$2" && echo "RENAMED: $1 -> $2"; }
else
    DEL() { echo "WOULD-DELETE: $1"; }
    DEL_DIR() { echo "WOULD-DELETE-DIR: $1"; }
    RENAME() { echo "WOULD-RENAME: $1 -> $2"; }
fi

# safe_delete: only delete $bad if $real exists. Lists the corresponding .jpg too.
safe_delete() {
    local bad="$1"
    local real="$2"
    if [ ! -f "$bad" ]; then echo "SKIP (not found): $bad"; return; fi
    if [ ! -f "$real" ]; then
        echo "SKIP (real file missing): would have deleted $bad expecting $real"
        return
    fi
    DEL "$bad"
    # Companion .jpg
    local bad_jpg="${bad%.epub}.jpg"
    [ -f "$bad_jpg" ] && DEL "$bad_jpg"
}

# safe_rename: rename $src to $dst only if $dst does not exist.
safe_rename() {
    local src="$1"
    local dst="$2"
    if [ ! -f "$src" ]; then echo "SKIP (not found): $src"; return; fi
    if [ -e "$dst" ]; then echo "SKIP (target exists): $src -> $dst"; return; fi
    RENAME "$src" "$dst"
    # Rename companion jpg too
    local src_jpg="${src%.epub}.jpg"
    local dst_jpg="${dst%.epub}.jpg"
    if [ -f "$src_jpg" ] && [ ! -e "$dst_jpg" ]; then
        RENAME "$src_jpg" "$dst_jpg"
    fi
}

echo "===== DELETES (misfiled — correct copies already exist elsewhere) ====="

# Brandon Sanderson tangles
safe_delete "$B/Brandon Sanderson/Words of Radiance.epub"                                   "$B/Brandon Sanderson/Mitosis.epub"
safe_delete "$B/Brandon Sanderson/Words of Radiance_ Book Two of - Brandon Sanderson.epub"  "$B/Brandon Sanderson/Tress of the Emerald Sea.epub"
safe_delete "$B/Brandon Sanderson/Words of Radiance_ The Stormlig - Brandon Sanderson.epub" "$B/Brandon Sanderson/Defending Elysium.epub"
safe_delete "$B/Brandon Sanderson/The Way of Kings_ The First Boo - Brandon Sanderson.epub" "$B/Brandon Sanderson/Wind and Truth.epub"

# Cecil Beaton folder is two misfiled M.C. Beatons
safe_delete "$B/Cecil Beaton/The Best of Beaton.epub" \
            "$B/M. C. Beaton/Agatha Raisin_ Hot to Trot - M.C. Beaton.epub"
safe_delete "$B/Cecil Beaton/The Best of Beaton, With Notes on the Photogr.epub" \
            "$B/M. C. Beaton/Agatha Raisin_ Dead on Target - M.C. Beaton.epub"

# Charlotte Templin: misfiled Marge Piercy
safe_delete "$B/Charlotte Templin/An Interview With Marge Piercy.epub" \
            "$B/Marge Piercy/Woman on the Edge of Time.epub"

# David Bolton: misfiled CN Lester
safe_delete "$B/David Bolton/Select.epub" "$B/CN Lester/Trans Like Me.epub"

# Ernest Cline doubles (no-ASIN dupes; keep "- Ernest Cline" versions which have ASIN)
safe_delete "$B/Ernest Cline/Armada.epub"          "$B/Ernest Cline/Armada - Ernest Cline.epub"
safe_delete "$B/Ernest Cline/Ready Player One.epub" "$B/Ernest Cline/Ready Player One - Ernest Cline.epub"
safe_delete "$B/Ernest Cline/Ready Player Two.epub" "$B/Ernest Cline/Ready Player Two - Ernest Cline.epub"

# Francine Beaton: misfiled M.C. Beaton
safe_delete "$B/Francine Beaton/Leading From the Front.epub" \
            "$B/M. C. Beaton/Agatha Raisin and the Blood of an Englishman.epub"

# Frank Herbert dupe
safe_delete "$B/Frank Herbert/Frank Herbert Omnibus.epub" "$B/Frank Herbert/Dune Messiah.epub"

# Gyorgy Martin: misfiled GRRM
safe_delete "$B/Gyorgy Martin/Game of Thrones Summary - Book One.epub" \
            "$B/George R.R. Martin/A Game of Thrones.epub"

# Ian Perkin: misfiled Sherlock
safe_delete "$B/Ian Perkin/The Sign of the Four.epub" \
            "$B/Sir Arthur Conan Doyle/The Adventures of Sherlock Holmes.epub"

# James S. A. Corey: untitled = Babylon's Ashes
safe_delete "$B/James S. A. Corey/Untitled James S. A. Corey Novel 3.epub" \
            "$B/James S. A. Corey/Babylon's Ashes.epub"

# Jim Butcher omnibuses (both misnamed for books we already have)
safe_delete "$B/Jim Butcher/The Dresden Files Series III 5 Book.epub" "$B/Jim Butcher/Dead Beat.epub"
safe_delete "$B/Jim Butcher/Jim Butcher's Dresden Files Omnibus Vol. 1.epub" "$B/Jim Butcher/Battle Ground.epub"

# Jonas Jonasson: short-name dupe
safe_delete "$B/Jonas Jonasson/The Hundred Year Old Man.epub" \
            "$B/Jonas Jonasson/The Hundred-Year-Old Man Who Climbed Out of the Window and Disappeared.epub"

# Jonathan Erickson: Facing Proteus is actually The Psychology of Zelda
safe_delete "$B/Jonathan Erickson/Facing Proteus.epub" \
            "$B/Jonathan Erickson/The Psychology of Zelda.epub"

# Leonardo da Vinci: same content twice; drop the "Complete" one
safe_delete "$B/Leonardo da Vinci/The Notebooks of Leonardo Da Vinci Complete.epub" \
            "$B/Leonardo da Vinci/The Notebooks of Leonardo Da Vinci.epub"

# Linwood Barclay: Poscig is Never Look Away
safe_delete "$B/Linwood Barclay/Poscig.epub" "$B/Linwood Barclay/Never Look Away.epub"

# Luo Guanzhong: Volume 1 is the Romance
safe_delete "$B/Luo Guanzhong/Three Kingdoms, Volume 1.epub" \
            "$B/Luo Guanzhong/The Romance of Three Kingdoms.epub"

# Margaret Atwood: Book of Lives is The Testaments
safe_delete "$B/Margaret Atwood/Book of Lives.epub" "$B/Margaret Atwood/The Testaments.epub"

# Martha Wells: Martha Wells.epub is Compulsory
safe_delete "$B/Martha Wells/Martha Wells.epub" "$B/Martha Wells/Compulsory.epub"

# Mary Pope Osborne — only Magic Tree House 3 remains; nothing to clean here

# M. C. Beaton: Death of a Cad is actually Killing Time
safe_delete "$B/M. C. Beaton/Death of a Cad.epub" \
            "$B/M. C. Beaton/Agatha Raisin_ Killing Time_ An irresistib - M.C. Beaton.epub"

# N. K. Jemisin: Untitled is The Obelisk Gate
safe_delete "$B/N. K. Jemisin/Untitled Jemisin 3.epub" "$B/N. K. Jemisin/The Obelisk Gate.epub"

# Pat Barker: Mixed B S is Silence of the Girls
safe_delete "$B/Pat Barker/Pat Barker Mixed B S.epub" "$B/Pat Barker/The Silence of the Girls.epub"

# Paul Dolan: Untitled is Happy Ever After
safe_delete "$B/Paul Dolan/Untitled Paul Dolan.epub" "$B/Paul Dolan/Happy Ever After.epub"

# Philip Pullman: Slipcase is The Secret Commonwealth
safe_delete "$B/Philip Pullman/Phillip Pulman Slipcase.epub" \
            "$B/Philip Pullman/The Secret Commonwealth.epub"

# Robert Jordan: Prepack is Towers of Midnight
safe_delete "$B/Robert Jordan/Robert Jordan B 12-C Prepack.epub" \
            "$B/Robert Jordan/Towers Of Midnight.epub"

# Robin Hobb: long-name with no ASIN — content is Assassin's Fate (already have)
safe_delete "$B/Robin Hobb/Assassin's Fate_ Book Three of - Robin Hobb.epub" \
            "$B/Robin Hobb/Assassin's Fate.epub"
# Fool's Quest_ Book Two — content is The Wilful Princess
safe_delete "$B/Robin Hobb/Fool's Quest_ Book Two of the F - Robin Hobb.epub" \
            "$B/Robin Hobb/The Wilful Princess and the Piebald Prince.epub"

# Sally Rooney: Collection Set is Normal People
safe_delete "$B/Sally Rooney/Sally Rooney 2 Books Collection Set.epub" \
            "$B/Sally Rooney/Normal People.epub"

# Terry Pratchett: Interesting Times is actually Eric (we have Eric)
safe_delete "$B/Terry Pratchett/Interesting Times.epub" "$B/Terry Pratchett/Eric.epub"

echo
echo "===== RENAMES ====="

# Brandon Sanderson - Words of Radiance lives in "Words of Radiance_ 3 (...)" (correct content,
# wrong filename). The bogus "Words of Radiance.epub" was deleted above, freeing the slot.
safe_rename "$B/Brandon Sanderson/Words of Radiance_ 3 (The Stormlight Archi - Brandon Sanderson.epub" \
            "$B/Brandon Sanderson/Words of Radiance.epub"

echo
echo "===== Remove now-empty misfiled author folders ====="
for d in "Cecil Beaton" "Charlotte Templin" "David Bolton" "Francine Beaton" "Gyorgy Martin" "Ian Perkin"; do
    full="$B/$d"
    if [ -d "$full" ]; then
        if [ -z "$(ls -A "$full" 2>/dev/null)" ]; then
            DEL_DIR "$full"
        else
            echo "SKIP (not empty): $full — contents: $(ls "$full")"
        fi
    fi
done

echo
echo "===== Final stats ====="
echo "Total .epub : $(find "$B" -name '*.epub' -type f | wc -l)"
echo "Total .jpg  : $(find "$B" -name '*.jpg'  -type f | wc -l)"
echo "Author dirs : $(ls "$B" | wc -l)"
REMOTE
