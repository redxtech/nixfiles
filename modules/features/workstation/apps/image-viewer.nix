{
  den.aspects.image-viewer.homeManager =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      home.packages = with pkgs; [
        qimgv # main image viewer
        satty # image editor
      ];

      xdg.configFile."qimgv/qimgv.conf".text = ''
        [General]
        JPEGSaveQuality=95
        absoluteZoomStep=false
        autoResizeLimit=90
        autoResizeWindow=false
        backgroundOpacity=1
        blurBackground=false
        clickableEdges=false
        clickableEdgesVisible=true
        confirmDelete=true
        confirmTrash=true
        cursorAutohiding=true
        defaultCropAction=0
        defaultFitMode=0
        defaultViewMode=0
        drawTransparencyGrid=false
        enableSmoothScroll=true
        expandImage=false
        expandLimit=2
        firstRun=false
        fixedZoomLevels="0.05,0.1,0.125,0.166,0.25,0.333,0.5,0.66,1,1.5,2,3,4,5,6,7,8"
        focusPointIn1to1Mode=1
        folderEndAction=1
        folderViewIconSize=120
        imageScrolling=2
        infoBarFullscreen=true
        infoBarWindowed=true
        jxlAnimation=false
        keepFitMode=false
        language=en_US
        lastVerMajor=1
        lastVerMicro=3
        lastVerMinor=0
        loopSlideshow=false
        memoryAllocationLimit=1024
        mpvBinary=${lib.getExe config.programs.mpv.package}
        openInFullscreen=false
        panelCenterSelection=false
        panelEnabled=true
        panelFullscreenOnly=true
        panelPinned=false
        panelPosition=top
        panelPreviewsSize=140
        playVideoSounds=false
        scalingFilter=1
        showSaveOverlay=true
        slideshowInterval=3000
        smoothAnimatedImages=true
        smoothUpscaling=true
        sortFolders=true
        sortingMode=0
        squareThumbnails=false
        thumbPanelStyle=1
        thumbnailCache=true
        thumbnailerThreads=4
        trackpadDetection=true
        unloadThumbs=true
        unlockMinZoom=true
        useFixedZoomLevels=false
        useOpenGL=false
        usePreloader=true
        useSystemColorScheme=false
        videoPlayback=true
        windowTitleExtendedInfo=true
        zoomIndicatorMode=2
        zoomStep=@Variant(\0\0\0\x87>L\xcc\xcd)

        [Controls]
        shortcuts="zoomIn=+", "frameStepBack=,", "zoomOut=-", "frameStep=.", "fitWindow=1", "fitWidth=2", "fitNormal=3", "exit=Alt+X", "folderView=Backspace", "copyFile=C", "copyFileClipboard=Ctrl+C", "showInDirectory=Ctrl+D", "zoomOut=Ctrl+Down", "rotateLeft=Ctrl+L", "seekVideoBackward=Ctrl+Left", "open=Ctrl+O", "print=Ctrl+P", "exit=Ctrl+Q", "rotateRight=Ctrl+R", "seekVideoForward=Ctrl+Right", "save=Ctrl+S", "copyPathClipboard=Ctrl+Shift+C", "saveAs=Ctrl+Shift+S", "zoomIn=Ctrl+Up", "pasteFile=Ctrl+V", "zoomOutCursor=Ctrl+WheelDown", "zoomInCursor=Ctrl+WheelUp", "discardEdits=Ctrl+Z", "toggleShuffle=Ctrl+`", "moveToTrash=Del", "scrollDown=Down", "jumpToLast=End", "folderView=Enter", "closeFullScreenOrExit=Esc", "toggleFullscreen=F", "toggleFullscreen=F11", "renameFile=F2", "reloadImage=F5", "flipH=H", "jumpToFirst=Home", "toggleImageInfo=I", "toggleFullscreen=LMB_DoubleClick", "prevImage=Left", "moveFile=M", "contextMenu=Menu", "exit=MiddleButton", "openSettings=P", "exit=Q", "resize=R", "contextMenu=RMB", "nextImage=Right", "removeFile=Shift+Del", "toggleFullscreenInfoBar=Shift+F", "prevDirectory=Shift+Left", "nextDirectory=Shift+Right", "toggleFitMode=Space", "scrollUp=Up", "flipV=V", "nextImage=WheelDown", "prevImage=WheelUp", "crop=X", "prevImage=XButton1", "nextImage=XButton2", "toggleSlideshow=`"

        [Scripts]
        script\1\name=Satty
        script\1\value=@Variant(\0\0\0\x7f\0\0\0\aScript\0\0\0\0.\0s\0\x61\0t\0t\0y\0 \0-\0-\0\x66\0i\0l\0\x65\0n\0\x61\0m\0\x65\0 \0%\0\x66\0i\0l\0\x65\0%\0)
        script\size=1
      '';
    };
}
