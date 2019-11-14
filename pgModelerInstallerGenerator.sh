#!/bin/bash
INSTALLDIR="$HOME"

usage() {
	tput bold
	tput setaf 7
	echo -e "\nTo see this message again, use -h (--help) flag.\n
	Use this installer with following syntax:\n
	\t$ ./pgModelerInstall.sh -t=\$VERSION
	or
	\t$ ./pgModelerInstall.sh --target=\$VERSION

	e.g. 
	\t./pgModelerInstall.sh -t=master
	or
	\t./pgModelerInstall.sh --target=v0.9.1
	"
	tput sgr0
	exit 0
}

if [ "$#" -eq 0 ]; then
	usage
	exit 0	
fi

for i in "$@"
do
	case $i in
		-t=*|--target=*)
			VERSION="${i#*=}"
			shift
			;;
		-h|--help)
			usage
			;;
		*)
			usage
			;;
	esac
done


if [ ! -f doneFirstRun ]; then
	touch doneFirstRun
	pacman -Sqyuu --noconfirm
else
	rm doneFirstRun
	pacman -Sqyuu --noconfirm
fi

pacman -Sq --noconfirm --needed pacman base-develop mingw-w64-x86_64-toolchain git

pacman -Sq --noconfirm --needed mingw-w64-x86_64-qt5 mingw-w64-x86_64-postgresql mingw-w64-x86_64-libxml2

# Install directory $HOME
cd $INSTALLDIR

git clone https://github.com/pgmodeler/pgmodeler.git

cd pgmodeler

if git checkout $VERSION ; then
	tput bold
	tput setaf 2
	echo -e "\nWorking with version $VERSION\n"
	tput sgr0
else
	tput bold
	tput setaf 1
	echo -e "\nVersion not found :(\n\tPlease set proper version: 'master', 'develop' or 'v\$tagnumber' with -t=version (--target=version)"
	tput sgr0
	exit 1
fi

cp pgmodeler.pri pgmodeler.pri.tmp1
sed '/!defined(PGSQL_LIB/c\!defined(PGSQL_LIB, var): PGSQL_LIB = C:\/msys64\/mingw64\/bin\/libpq.dll' pgmodeler.pri.tmp1 > pgmodeler.pri
cp pgmodeler.pri pgmodeler.pri.tmp2
sed '/!defined(PGSQL_INC/c\!defined(PGSQL_INC, var): PGSQL_INC = C:\/msys64\/mingw64\/include' pgmodeler.pri.tmp2 > pgmodeler.pri
cp pgmodeler.pri pgmodeler.pri.tmp3
sed '/!defined(XML_INC/c\!defined(XML_INC, var): XML_INC = C:\/msys64\/mingw64\/include\/libxml2' pgmodeler.pri.tmp3 > pgmodeler.pri
cp pgmodeler.pri pgmodeler.pri.tmp4
sed '/!defined(XML_LIB/c\!defined(XML_LIB, var): XML_LIB = C:\/msys64\/mingw64\/bin\/libxml2-2.dll' pgmodeler.pri.tmp4 > pgmodeler.pri
rm pgmodeler.pri.tmp*

qmake pgmodeler.pro

make -j $(nproc --all) -s

make install -s

cd build

windeployqt --compiler-runtime pgmodeler.exe

cp /mingw64/bin/libfreetype-6.dll /mingw64/bin/libgraphite2.dll /mingw64/bin/libharfbuzz-0.dll /mingw64/bin/libiconv-2.dll /mingw64/bin/libicudt*.dll /mingw64/bin/libicuin*.dll /mingw64/bin/libicuuc*.dll /mingw64/bin/libintl-8.dll . 2>/dev/null
cp /mingw64/bin/liblzma-5.dll /mingw64/bin/libpcre-1.dll /mingw64/bin/libpcre2-16-0.dll /mingw64/bin/libpng16-16.dll /mingw64/bin/libpq.dll /mingw64/bin/libxml2-2.dll /mingw64/bin/libbz2-1.dll . 2>/dev/null
cp /mingw64/bin/Qt5Networkd.dll /mingw64/bin/libssl-1_1-x64.dll /mingw64/bin/libcrypto-1_1-x64.dll /mingw64/bin/libgcc_s_seh-1.dll /mingw64/bin/libstdc++-6.dll /mingw64/bin/libwinpthread-1.dll /mingw64/bin/liblzma-5.dll . 2>/dev/null
cp /mingw64/bin/libzstd.dll /mingw64/bin/libglib-2.0-0.dll /mingw64/bin/libdouble-conversion.dll /mingw64/bin/Qt5PrintSupportd.dll /mingw64/bin/zlib1.dll . 2>/dev/null

cd ..

"/c/Program Files (x86)/Inno Setup 6/ISCC.exe" /Q ./installer/windows/pgmodeler.iss

echo -e "\nOK !"
