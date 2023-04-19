cd "$(dirname "$0")"

[ -e images ] && rm -rf images
mkdir images/

mkdir bare/
cp setup.sh bare/
mkisofs -U -V "ArchSetup" -o images/bare.iso bare/
rm -rf bare/

# [ -e archlive/airootfs/bin/archsetup ] && rm archlive/airootfs/bin/archsetup
# cp setup.sh archlive/airootfs/usr/local/bin/setup
# sudo mkarchiso -v -w /tmp/archiso-tmp -o images archlive/
