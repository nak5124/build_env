#!/usr/bin/env bash


pushd /usr/bin > /dev/null

# asciidoc
ln -fsr ./a2x.py ./a2x
ln -fsr ./asciidoc.py ./asciidoc

# bash
ln -fsr ./bash.exe ./sh.exe

# binutils-git
ln -fsr ./ld.bfd.exe ./ld.exe
ln -fsr ./ar.exe ../x86_64-pc-msys/bin/ar.exe
ln -fsr ./as.exe ../x86_64-pc-msys/bin/as.exe
ln -fsr ./dlltool.exe ../x86_64-pc-msys/bin/dlltool.exe
ln -fsr ./ld.bfd.exe ../x86_64-pc-msys/bin/ld.bfd.exe
ln -fsr ./ld.bfd.exe ../x86_64-pc-msys/bin/ld.exe
ln -fsr ./nm.exe ../x86_64-pc-msys/bin/nm.exe
ln -fsr ./objcopy.exe ../x86_64-pc-msys/bin/objcopy.exe
ln -fsr ./objdump.exe ../x86_64-pc-msys/bin/objdump.exe
ln -fsr ./ranlib.exe ../x86_64-pc-msys/bin/ranlib.exe
ln -fsr ./strip.exe ../x86_64-pc-msys/bin/strip.exe

# bzip2
ln -fsr ./bzip2.exe ./bunzip2.exe
ln -fsr ./bzip2.exe ./bzcat.exe
ln -fsr ./bzdiff ./bzcmp
ln -fsr ./bzgrep ./bzegrep
ln -fsr ./bzgrep ./bzfgrep
ln -fsr ./bzless ./bzmore

# cocom
ln -fsr ./dino-0.55.exe ./dino.exe

# dash
ln -fsr ./dash.exe ./ash.exe

# dos2unix
ln -fsr ./dos2unix.exe ./d2u.exe
ln -fsr ./unix2dos.exe ./u2d.exe

# flex
ln -fsr ./flex.exe ./flex++.exe
ln -fsr ./flex.exe ./lex.exe

# gawk
ln -fsr ./gawk-4.1.3.exe ./gawk.exe
ln -fsr ./gawk.exe ./awk.exe

# gcc
ln -fsr ./cpp.exe ../lib/cpp.exe
ln -fsr ./gcc.exe ./cc.exe
ln -fsr ./gcc.exe ./x86_64-pc-msys-gcc.exe
ln -fsr ./gcc.exe ./x86_64-pc-msys-gcc-4.9.2.exe
ln -fsr ./gcc-ar.exe ./x86_64-pc-msys-gcc-ar.exe
ln -fsr ./gcc-nm.exe ./x86_64-pc-msys-gcc-nm.exe
ln -fsr ./gcc-ranlib.exe ./x86_64-pc-msys-gcc-ranlib.exe
ln -fsr ./g++.exe ./c++.exe
ln -fsr ./g++.exe ./x86_64-pc-msys-g++.exe
ln -fsr ./c++.exe ./x86_64-pc-msys-c++.exe

# gcc-libs
rm -f ./msys-gfortran-*.dll

# git
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-bisect--helper.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-apply.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-archive.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-blame.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-annotate.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-add.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-branch.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-bundle.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-cat-file.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-check-attr.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-check-ignore.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-check-mailmap.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-check-ref-format.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-checkout-index.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-checkout.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-cherry-pick.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-cherry.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-clean.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-clone.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-column.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-commit-tree.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-commit.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-config.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-count-objects.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-credential.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-describe.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-diff-files.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-diff-index.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-diff-tree.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-diff.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-fast-export.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-fetch-pack.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-fetch.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-fmt-merge-msg.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-for-each-ref.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-format-patch.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-fsck-objects.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-fsck.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-gc.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-get-tar-commit-id.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-grep.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-hash-object.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-help.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-index-pack.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-interpret-trailers.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-init-db.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-init.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-log.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-ls-files.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-ls-remote.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-ls-tree.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-mailinfo.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-mailsplit.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-merge-base.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-merge-file.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-merge-index.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-merge-ours.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-merge-recursive.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-merge-subtree.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-merge-tree.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-merge.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-mktag.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-mktree.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-mv.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-name-rev.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-notes.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-pack-objects.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-pack-redundant.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-pack-refs.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-patch-id.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-prune-packed.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-prune.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-push.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-read-tree.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-receive-pack.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-reflog.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-remote-ext.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-remote-fd.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-remote.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-repack.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-replace.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-rerere.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-reset.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-rev-list.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-rev-parse.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-revert.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-rm.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-send-pack.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-shortlog.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-show-branch.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-show-ref.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-show.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-stage.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-status.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-stripspace.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-symbolic-ref.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-tag.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-unpack-file.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-unpack-objects.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-update-index.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-update-ref.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-update-server-info.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-upload-archive.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-var.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-verify-commit.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-verify-pack.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-verify-tag.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-whatchanged.exe
ln -fsr ../lib/git-core/git.exe ../lib/git-core/git-write-tree.exe
ln -fsr ../lib/git-core/git.exe ./git-receive-pack.exe
ln -fsr ../lib/git-core/git.exe ./git-upload-archive.exe
ln -fsr ../lib/git-core/git.exe ./git.exe
ln -fsr ../lib/git-core/git-upload-pack.exe ./git-upload-pack.exe
ln -fsr ../lib/git-core/git-shell.exe ./git-shell.exe
ln -fsr ../lib/git-core/git-cvsserver ./git-cvsserver
ln -fsr ../lib/git-core/git-remote-http.exe ../lib/git-core/git-remote-ftp.exe
ln -fsr ../lib/git-core/git-remote-http.exe ../lib/git-core/git-remote-ftps.exe
ln -fsr ../lib/git-core/git-remote-http.exe ../lib/git-core/git-remote-https.exe
ln -fsr ../lib/git-core/git-gui ../lib/git-core/git-citool

# groff
ln -fsr ./roff2dvi ./roff2html
ln -fsr ./roff2dvi ./roff2pdf
ln -fsr ./roff2dvi ./roff2ps
ln -fsr ./roff2dvi ./roff2text
ln -fsr ./roff2dvi ./roff2x

# gzip
ln -fsr ./gunzip ./uncompress

# icu-devel
ln -fsr ../lib/libicui18n51.dll.a ../lib/libicui18n.dll.a
ln -fsr ../lib/libicuuc51.dll.a ../lib/libicuuc.dll.a
ln -fsr ../lib/libicule51.dll.a ../lib/libicule.dll.a
ln -fsr ../lib/libicutu51.dll.a ../lib/libicutu.dll.a
ln -fsr ../lib/libiculx51.dll.a ../lib/libiculx.dll.a
ln -fsr ../lib/libicutest51.dll.a ../lib/libicutest.dll.a
ln -fsr ../lib/libicuio51.dll.a ../lib/libicuio.dll.a

# libdb-devel
ln -fsr ../lib/libdb-5.3.a ../lib/libdb.a
ln -fsr ../lib/libdb-5.3.dll.a ../lib/libdb.dll.a
ln -fsr ../lib/libdb_cxx-5.3.a ../lib/libdb_cxx.a
ln -fsr ../lib/libdb_cxx-5.3.dll.a ../lib/libdb_cxx.dll.a

# libtool
rm -fr /usr/share/libtool/config
ln -fsr ../share/libtool/build-aux ../share/libtool/config

# man-db
ln -fsr ./whatis.exe ./apropos.exe

# mc
ln -fsr ./mc.exe ./mcdiff.exe
ln -fsr ./mc.exe ./mcedit.exe
ln -fsr ./mc.exe ./mcview.exe

# mingw-w64-cross-binutils
ln -fsr ../../opt/bin/x86_64-w64-mingw32-ld.exe ../../opt/bin/x86_64-w64-mingw32-ld.bfd.exe
ln -fsr ../../opt/bin/x86_64-w64-mingw32-ar.exe ../../opt/x86_64-w64-mingw32/bin/ar.exe
ln -fsr ../../opt/bin/x86_64-w64-mingw32-as.exe ../../opt/x86_64-w64-mingw32/bin/as.exe
ln -fsr ../../opt/bin/x86_64-w64-mingw32-dlltool.exe ../../opt/x86_64-w64-mingw32/bin/dlltool.exe
ln -fsr ../../opt/bin/x86_64-w64-mingw32-ld.bfd.exe ../../opt/x86_64-w64-mingw32/bin/ld.bfd.exe
ln -fsr ../../opt/bin/x86_64-w64-mingw32-ld.bfd.exe ../../opt/x86_64-w64-mingw32/bin/ld.exe
ln -fsr ../../opt/bin/x86_64-w64-mingw32-nm.exe ../../opt/x86_64-w64-mingw32/bin/nm.exe
ln -fsr ../../opt/bin/x86_64-w64-mingw32-objcopy.exe ../../opt/x86_64-w64-mingw32/bin/objcopy.exe
ln -fsr ../../opt/bin/x86_64-w64-mingw32-objdump.exe ../../opt/x86_64-w64-mingw32/bin/objdump.exe
ln -fsr ../../opt/bin/x86_64-w64-mingw32-ranlib.exe ../../opt/x86_64-w64-mingw32/bin/ranlib.exe
ln -fsr ../../opt/bin/x86_64-w64-mingw32-strip.exe ../../opt/x86_64-w64-mingw32/bin/strip.exe

# mingw-w64-cross-gcc
rm -f /opt/bin/i686-w64-mingw32-*.exe
rm -fr /opt/i686-w64-mingw32
rm -fr /opt/lib/gcc/i686-w64-mingw32
rm -f /opt/bin/x86_64-w64-mingw32-gfortran.exe
rm -f /opt/lib/gcc/x86_64-w64-mingw32/4.9.2/{f951.exe,libgfortran.a,libgfortran.dll.a,libgfortran-3.dll,libcaf_single.a,libgfortranbegin.a,libstdc++.dll.a-gdb.py,libgfortran.spec}
rm -fr /opt/lib/gcc/x86_64-w64-mingw32/4.9.2/finclude
ln -fsr ../../opt/bin/x86_64-w64-mingw32-gcc.exe ../../opt/bin/x86_64-w64-mingw32-gcc-4.9.2.exe
ln -fsr ../../opt/bin/x86_64-w64-mingw32-g++.exe ../../opt/bin/x86_64-w64-mingw32-c++.exe

# msys2-runtime-devel
rm -f ./msys-2.0.dbg
ln -fsr ../lib/libmsys-2.0.a ../lib/libg.a

# ncurses-devel
ln -fsr ./tic.exe ./captoinfo.exe
ln -fsr ./tic.exe ./infotocap.exe
ln -fsr ../lib/libncursesw.a ../lib/libncurses.a
ln -fsr ../lib/libncursesw.dll.a ../lib/libncurses.dll.a
rm -fr /usr/include/ncurses
ln -fsr ../include/ncursesw ../include/ncurses
ln -fsr ../include/ncursesw/unctrl.h ../include

# openssh
ln -fsr ./ssh.exe ./slogin.exe

# pkgconf
ln -fsr ./pkgconf.exe ./pkg-config.exe

# procps
ln -fsr ./pkill.exe ./pgrep.exe
ln -fsr ./prockill.exe ./skill.exe
ln -fsr ./prockill.exe ./snice.exe

# psmisc
ln -fsr ./pstree.exe ./pstree.x11.exe

# python
ln -fsr ./python3.4m.exe ./python3.4.exe
ln -fsr ./python3.4.exe ./python3.exe
ln -fsr ./python3.4.exe ./python.exe
ln -fsr ./python3.4m-config ./python3.4-config
ln -fsr ./python3.4-config ./python3-config
ln -fsr ./python3.4-config ./python-config
ln -fsr ./pyvenv-3.4 ./pyvenv
ln -fsr ./2to3-3.4 ./2to3
ln -fsr ./idle3.4 ./idle3
ln -fsr ./idle3 ./idle
ln -fsr ./pydoc3.4 ./pydoc3
ln -fsr ./pydoc3 ./pydoc
ln -fsr ../lib/pkgconfig/python-3.4m.pc ../lib/pkgconfig/python-3.4.pc
ln -fsr ../lib/pkgconfig/python-3.4.pc ../lib/pkgconfig/python3.pc

# python2
ln -fsr ./python2.7.exe ./python2.exe
ln -fsr ./python2.7-config ./python2-config
ln -fsr ../lib/pkgconfig/python-2.7.pc ../lib/pkgconfig/python2.pc

# subversion
ln -fsr ./svn-tools/svnauthz.exe ./svn-tools/svnauthz-validate.exe
ln -fsr ../share/bash-completion/completions/subversion ../share/bash-completion/completions/svn
ln -fsr ../share/bash-completion/completions/subversion ../share/bash-completion/completions/svnadmin
ln -fsr ../share/bash-completion/completions/subversion ../share/bash-completion/completions/svndumpfilter
ln -fsr ../share/bash-completion/completions/subversion ../share/bash-completion/completions/svnlook
ln -fsr ../share/bash-completion/completions/subversion ../share/bash-completion/completions/svnsync
ln -fsr ../share/bash-completion/completions/subversion ../share/bash-completion/completions/svnversion

# texinfo
ln -fsr ./makeinfo ./texi2any
ln -fsr ./texi2pdf ./pdftexi2dvi

# tzcode
# rm -fr /usr/share/zoneinfo/posix
# ln -fsr ../share/zoneinfo/zoneinfo ../share/zoneinfo/posix

# unzip
ln -fsr ./unzip.exe ./zipinfo.exe

# vim
ln -fsr ./vim.exe ./vi.exe
ln -fsr ./vim.exe ./ex.exe
ln -fsr ./vim.exe ./rview.exe
ln -fsr ./vim.exe ./rvim.exe
ln -fsr ./vim.exe ./view.exe
ln -fsr ./vim.exe ./vimdiff.exe

# xz
ln -fsr ./xz.exe ./lzcat.exe
ln -fsr ./xz.exe ./lzma.exe
ln -fsr ./xz.exe ./unlzma.exe
ln -fsr ./xz.exe ./unxz.exe
ln -fsr ./xz.exe ./xzcat.exe
ln -fsr ./xzcmp ./xzdiff
ln -fsr ./xzcmp ./lzcmp
ln -fsr ./xzcmp ./lzdirr
ln -fsr ./xzgrep ./xzegrep
ln -fsr ./xzgrep ./xzfgrep
ln -fsr ./xzgrep ./lzgrep
ln -fsr ./xzgrep ./lzegrep
ln -fsr ./xzgrep ./lzfgrep
ln -fsr ./xzless ./lzless

popd > /dev/null
