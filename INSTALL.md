# Toolkit deployment instructions

__Note__: These instructions only apply to the public serving of the toolkit part of this
project at [infra.clarin.eu/CMDI](https://infra.clarin.eu/CMDI).

- Login to the machine that hosts infra.clarin.eu
- Go to `${WWW_INFRA_CLARIN_DIR}/CMDI` (e.g. `/srv/www/infra.clarin.eu/CMDI`)
- Check whether https://infra.clarin.eu/CMDI/ is indeed being served from this path
- Download and extract the public toolkit part of the package. E.g. for version 1.2.2:
```sh
TOOLKIT_VERSION=1.2.2
(mkdir $TOOLKIT_VERSION && cd $TOOLKIT_VERSION && \
    curl -L "https://github.com/clarin-eric/cmdi-toolkit/archive/cmdi-${TOOLKIT_VERSION}.tar.gz" | tar zxvf - --strip-components 5 -- cmdi-toolkit-cmdi-${TOOLKIT_VERSION}/src/main/resources/toolkit) || echo FAILED > /dev/stderr
```
- Update the symlink for the minor version to the latest subminor version; e.g.
```sh
TOOLKIT_MINOR=1.2; TOOLKIT_VERSION=1.2.2
([ -h $TOOLKIT_MINOR ] && unlink $TOOLKIT_MINOR && ln -s $TOOLKIT_VERSION $TOOLKIT_MINOR && ls -l ${TOOLKIT_MINOR}) || echo "SYMLINK '${TOOLKIT_MINOR}' NOT UPDATED" > /dev/stderr
```
