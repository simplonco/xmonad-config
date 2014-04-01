for f in $(ls -F | grep  \*); do
	ln -s $f ~/bin
done

ln -s ~/.xmonad/xmobarrc ~/.xmobarrc
