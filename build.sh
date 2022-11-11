#!/bin/sh
echo SOURCECODEURL: "$SOURCECODEURL"
echo PKGNAME: "$PKGNAME"
echo BOARD: "$BOARD"
EMAIL=${EMAIL:-"aa@163.com"}
echo EMAIL: "$EMAIL"
echo PASSWORD: "$PASSWORD"

WORKDIR="$(pwd)"

sudo -E apt-get update
sudo -E apt-get install git  asciidoc bash bc binutils bzip2 fastjar flex gawk gcc genisoimage gettext git intltool jikespg libgtk2.0-dev libncurses5-dev libssl1.0-dev make mercurial patch perl-modules python2.7-dev rsync ruby sdcc subversion unzip util-linux wget xsltproc zlib1g-dev zlib1g-dev -y

git config --global user.email "${EMAIL}"
git config --global user.name "aa"
[ -n "${PASSWORD}" ] && git config --global user.password "${PASSWORD}"

# 下载需要编译插件的源代码
mkdir -p  ${WORKDIR}/buildsource
cd  ${WORKDIR}/buildsource
git clone "$SOURCECODEURL"
cd  ${WORKDIR}

mips_siflower_sdk_get()
{
	git clone https://github.com/gl-inet-builder/openwrt-sdk-siflower-1806.git openwrt-sdk
}

axt1800_sdk_get()
{
	wget -q -O openwrt-sdk.tar.xz https://fw.gl-inet.com/releases/v21.02-SNAPSHOT/sdk/openwrt-sdk-ipq807x-ipq60xx_gcc-5.5.0_musl_eabi.Linux-x86_64.tar.xz
	mkdir -p ${WORKDIR}/openwrt-sdk
	tar -Jxf openwrt-sdk.tar.xz -C ${WORKDIR}/openwrt-sdk --strip=1
	echo src-git packages https://git.openwrt.org/feed/packages.git^78bcd00c13587571b5c79ed2fc3363aa674aaef7 >${WORKDIR}/openwrt-sdk/feeds.conf.default
	echo src-git routing https://git.openwrt.org/feed/routing.git^a0d61bddb3ce4ca54bd76af86c28f58feb6cc044 >>${WORKDIR}/openwrt-sdk/feeds.conf.default
	echo src-git telephony https://git.openwrt.org/feed/telephony.git^0183c1adda0e7581698b0ea4bff7c08379acf447 >>${WORKDIR}/openwrt-sdk/feeds.conf.default
	echo src-git luci https://git.openwrt.org/feed/routing.git^a0d61bddb3ce4ca54bd76af86c28f58feb6cc044 >>${WORKDIR}/openwrt-sdk/feeds.conf.default
	
	sed -i '246,258d' ${WORKDIR}/openwrt-sdk/include/package-ipkg.mk
}

x86_sdk_get()
{
	wget -q -O openwrt-sdk.tar.xz https://downloads.openwrt.org/releases/21.02.3/targets/x86/64/openwrt-sdk-21.02.3-x86-64_gcc-8.4.0_musl.Linux-x86_64.tar.xz
	mkdir -p ${WORKDIR}/openwrt-sdk
	tar -Jxf openwrt-sdk.tar.xz -C ${WORKDIR}/openwrt-sdk --strip=1
}

case "$BOARD" in
	"SF1200" |\
	"SFT1200" )
		mips_siflower_sdk_get
	;;
	"AXT1800" )
		axt1800_sdk_get
	;;
	"X86" )
		x86_sdk_get
	;;
	*)
esac

cd openwrt-sdk
# 加入要编译插件的代码
sed -i "1i\src-link githubaction ${WORKDIR}/buildsource" feeds.conf.default

ls -l
cat feeds.conf.default

./scripts/feeds update -a
./scripts/feeds install -a
echo CONFIG_ALL=y >.config
make defconfig
make V=s ./package/feeds/githubaction/${PKGNAME}/compile

find bin -type f -exec ls -lh {} \;
find bin -type f -name "*.ipk" -exec cp -f {} "${WORKDIR}" \; 
