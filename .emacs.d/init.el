;;; init.el --- emacs init file

;;; Commentary:
;;;

;;; Code:

;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
;; (package-initialize)

* Package Management
#+BEGIN_SRC emacs-lisp
;;; Package Management
(require 'package)

(setq-default package-archives
              '(("gnu"     . "https://elpa.gnu.org/packages/")
                ("melpa"        . "https://melpa.org/packages/")
                ("melpa-stable" . "https://stable.melpa.org/packages/"))
              package-archive-priorities
              '(("gnu" . 1)
                ("melpa" . 10)
                ("melpa-stable" . 0)))

(setq package-enable-at-startup nil)
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t
      use-package-always-demand t)
#+END_SRC
* Customize File
Move Emacs's customize settings to a separate file.
#+BEGIN_SRC emacs-lisp
(setq custom-file (expand-file-name "custom-file.el" user-emacs-directory))
(load custom-file 'noerror)
#+END_SRC
* Evil
Vim-like keybindings.
#+BEGIN_SRC emacs-lisp
(use-package goto-chg)

(use-package evil
  :custom
  (evil-move-beyond-eol nil)
  (evil-want-fine-undo t)
  (evil-want-keybinding nil)
  (evil-want-Y-yank-to-eol t)
  :config
  (add-hook 'prog-mode-hook #'hs-minor-mode)
  (evil-mode 1))

(use-package evil-collection
  :after evil
  :custom
  (evil-collection-setup-minibuffer nil)
  :config
  (evil-collection-init))

(use-package evil-escape
  :after evil
  :custom
  (evil-escape-key-sequence "fd")
  (evil-escape-delay 0.1)
  :config
  (evil-escape-mode 1))

(use-package evil-anzu
  :after evil)
#+END_SRC
* Leader Keymap
#+BEGIN_SRC emacs-lisp
(use-package general
  :config
  (general-override-mode)
  (general-evil-setup)
  (general-define-key
   :states '(insert normal operator motion visual)
   :keymaps 'override
   :prefix "SPC"
   :non-normal-prefix "M-p"
   :prefix-map 'panda/leader-map)
  (general-create-definer panda/general-leader
    :keymaps 'panda/leader-map))
#+END_SRC
* Appearance
** Defaults
#+BEGIN_SRC emacs-lisp
(setq default-frame-alist '((fullscreen . maximized)
                            (font . "Consolas-11")
                            (menu-bar-lines . 0)
                            (tool-bar-lines . 0)
                            (vertical-scroll-bars . nil))
      inhibit-startup-screen t
      ring-bell-function 'ignore
      visible-bell nil)
#+END_SRC
** Theme
#+BEGIN_SRC emacs-lisp
(use-package monokai-theme)

(load-theme 'monokai t)
#+END_SRC
** Mode Line
#+BEGIN_SRC emacs-lisp
(use-package doom-modeline
  :custom
  (doom-modeline-icon nil)
  (doom-modeline-buffer-file-name-style 'relative-from-project)
  :config
  (doom-modeline-init))
#+END_SRC
** Diminish
Hide ~abbrev-mode~ and ~auto-revert-mode~ from the mode line.
#+BEGIN_SRC emacs-lisp
(use-package diminish
  :config
  (diminish 'abbrev-mode)
  (diminish 'auto-revert-mode))
#+END_SRC
** Line Numbers
#+BEGIN_SRC emacs-lisp
(use-package linum-relative
  :custom
  (linum-relative-backend 'display-line-numbers-mode)
  :config
  (linum-relative-global-mode 1))

(column-number-mode 1)
#+END_SRC
** Cursor Beacon
#+BEGIN_SRC emacs-lisp
(use-package beacon
  :diminish beacon-mode
  :custom
  (beacon-blink-when-window-scrolls t)
  (beacon-blink-when-window-changes t)
  (beacon-blink-when-point-moves nil)
  :config
  (beacon-mode 1))
#+END_SRC
** Rainbow Delimiters
#+BEGIN_SRC emacs-lisp
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))
#+END_SRC
* Basic Configuration
** Defaults
#+BEGIN_SRC emacs-lisp
(setq auto-save-default nil
      c-default-style '((java-mode . "java")
                        (awk-mode . "awk")
                        (other . "linux"))
      disabled-command-function nil
      inhibit-compacting-font-caches t
      make-backup-files nil)

(setq-default buffer-file-coding-system 'utf-8
              c-basic-offset 4
              indent-tabs-mode nil
              tab-width 4)

(delete-selection-mode 1)
(electric-pair-mode 1)
(show-paren-mode 1)

(global-auto-revert-mode t)
#+END_SRC
** Key Definitions
*** Remaps
#+BEGIN_SRC emacs-lisp
(panda/general-leader
  "k" 'kill-buffer
  "o" 'occur
  "O" 'multi-occur)
#+END_SRC
*** Keybind Help
#+BEGIN_SRC emacs-lisp
(use-package which-key
  :diminish which-key-mode
  :custom
  (which-key-popup-type 'side-window)
  (which-key-side-window-location 'bottom)
  (which-key-idle-delay 1.0)
  :config
  (which-key-mode 1))
#+END_SRC
** Constants
*** Colors
Colors that look nice with Monokai.
#+BEGIN_SRC emacs-lisp
(defconst panda/neon-green "#39FF14")
(defconst panda/light-blue "#67C8FF")
(defconst panda/deep-saffron "#FF9933")
#+END_SRC
* Miscellaneous Packages
#+BEGIN_SRC emacs-lisp
(use-package esup)

(use-package fireplace)

(use-package hydra)

(use-package pacmacs)
#+END_SRC
* Global Packages
** Multi-Purpose
*** Ivy / Counsel / Swiper
Completion for emacs commands.
~flx~ and ~smex~ give better regex sorting and completion sorting, respectively.

Dependencies:
- [[https://github.com/BurntSushi/ripgrep][ripgrep]]
#+BEGIN_SRC emacs-lisp
(use-package flx)

(use-package smex)

(use-package ivy
  :diminish ivy-mode
  :general
  (panda/general-leader
    "s" 'swiper
    "b" 'ivy-switch-buffer)
  (general-imap
    :keymaps 'ivy-minibuffer-map
    "<return>" 'ivy-alt-done)
  :custom
  (ivy-wrap t)
  (ivy-re-builders-alist '((swiper . ivy--regex-plus)
                           (t . ivy--regex-fuzzy)))
  (confirm-nonexistent-file-or-buffer t)
  (ivy-count-format "(%d/%d) ")
  :config
  (ivy-mode 1)
  (set-face-attribute 'ivy-minibuffer-match-face-2 nil
                      :foreground panda/neon-green
                      :weight 'bold)
  (set-face-attribute 'ivy-minibuffer-match-face-3 nil
                      :foreground panda/light-blue
                      :weight 'bold)
  (set-face-attribute 'ivy-minibuffer-match-face-4 nil
                      :foreground panda/deep-saffron
                      :weight 'bold)
  (set-face-attribute 'ivy-confirm-face nil
                      :foreground panda/neon-green))

(use-package counsel
  :general
  (panda/general-leader
    "f" 'counsel-find-file
    "r" 'counsel-rg
    "P" 'counsel-yank-pop
    "p" 'panda/counsel-yank-pop-after)
  :config
  (defun panda/counsel-yank-pop-after (&optional arg)
    (interactive)
    (let ((evil-move-beyond-eol t))
      (forward-char)
      (call-interactively #'counsel-yank-pop arg)))
  (counsel-mode 1))
#+END_SRC
*** Crux
Miscellaneous functions.
#+BEGIN_SRC emacs-lisp
(use-package crux
  :commands (crux-rename-file-and-buffer crux-delete-file-and-buffer)
  :general
  (panda/general-leader
    "z" 'crux-find-user-init-file
    "x" 'crux-eval-and-replace)
  :config
  (define-advice crux-find-user-init-file (:override ())
    (find-file org-config-path))
  (define-advice crux-eval-and-replace (:around (old-func))
    (let ((evil-move-beyond-eol t))
      (save-excursion
        (forward-char)
        (call-interactively old-func)))))
#+END_SRC
** Executing Code
*** Quickrun
Run code from the current buffer with ~M-x quickrun~.
For interactive code, use ~M-x quickrun-shell~.
#+BEGIN_SRC emacs-lisp
(use-package quickrun)
#+END_SRC
*** Realgud
Package for debugging code. Use ~realgud:<debugger-name>~ to run a debugger.
#+BEGIN_SRC emacs-lisp
(use-package realgud)
#+END_SRC
** Editing
*** Evil Multiple Cursors
#+BEGIN_SRC emacs-lisp
(use-package evil-mc
  :general
  (panda/general-leader "m" 'panda/evil-mc/body)
  :init
  (defvar evil-mc-key-map (make-sparse-keymap))
  :config
  (defhydra panda/evil-mc (:hint nil :color pink :post (anzu--reset-mode-line))
    "
  evil-mc
  [_c_]: make cursor here     [_a_]: make cursors (all)    [_s_]: stop cursors          [_r_]: resume cursors
  [_p_]: prev match           [_n_]: next match            [_b_]: prev cursor           [_f_]: next cursor
  [_P_]: prev match (skip)    [_N_]: next match (skip)     [_B_]: prev cursor (skip)    [_F_]: next cursor (skip)
  [_u_]: undo all             [_/_]: cancel"
    ("c" evil-mc-make-cursor-here)
    ("a" evil-mc-make-all-cursors)
    ("s" evil-mc-pause-cursors)
    ("r" evil-mc-resume-cursors)
    ("p" evil-mc-make-and-goto-prev-match)
    ("n" evil-mc-make-and-goto-next-match)
    ("b" evil-mc-make-and-goto-prev-cursor)
    ("f" evil-mc-make-and-goto-next-cursor)
    ("P" evil-mc-skip-and-goto-prev-match)
    ("N" evil-mc-skip-and-goto-next-match)
    ("B" evil-mc-skip-and-goto-prev-cursor)
    ("F" evil-mc-skip-and-goto-next-cursor)
    ("u" evil-mc-undo-all-cursors :color blue)
    ("/" (message "Abort") :color blue))
  (global-evil-mc-mode 1))
#+END_SRC
*** Evil Surround
Edit delimiters like Vim Surround.
#+BEGIN_SRC emacs-lisp
(use-package evil-surround
  :after evil
  :config
  (global-evil-surround-mode 1))
#+END_SRC
*** Expand Region
Expand selected region.
#+BEGIN_SRC emacs-lisp
(use-package expand-region
  :general
  (general-imap "C-;" 'er/expand-region)
  (general-vmap ";" 'er/expand-region))
#+END_SRC
*** Undo Tree
Linear undo and redo.
#+BEGIN_SRC emacs-lisp
(use-package undo-tree
  :general
  (panda/general-leader "u" 'undo-tree-visualize)
  :config
  (global-undo-tree-mode))
#+END_SRC
** Git
*** Magit
Git interface.

Dependencies:
- [[https://git-scm.com/downloads][git]]
#+BEGIN_SRC emacs-lisp
(use-package magit
  :general
  (panda/general-leader "g" 'magit-status)
  :custom
  (magit-auto-revert-mode nil))

(use-package evil-magit
  :after magit)
#+END_SRC
*** Git Timemachine
Walk through git history.

Dependencies:
- [[https://git-scm.com/downloads][git]]
#+BEGIN_SRC emacs-lisp
(use-package git-timemachine
  :general
  (panda/general-leader "t" 'git-timemachine))
#+END_SRC
** Navigation
*** Avy
Jump to a word on the screen.
#+BEGIN_SRC emacs-lisp
(use-package avy
  :general
  (panda/general-leader "SPC" 'avy-goto-word-1)
  :custom
  (avy-background t)
  :config
  (set-face-attribute 'avy-lead-face nil
                      :foreground panda/neon-green
                      :background (face-attribute 'default :background)
                      :weight 'bold)
  (set-face-attribute 'avy-lead-face-0 nil
                      :foreground panda/light-blue
                      :background (face-attribute 'default :background)
                      :weight 'bold)
  (set-face-attribute 'avy-lead-face-2 nil
                      :foreground panda/deep-saffron
                      :background (face-attribute 'default :background)
                      :weight 'bold))
#+END_SRC
*** IMenu
Jump between definitions.
#+BEGIN_SRC emacs-lisp
(use-package imenu
  :general
  (panda/general-leader "i" 'imenu)
  :custom
  (imenu-auto-rescan t))
#+END_SRC
*** Neotree
Navigate a directory.
#+BEGIN_SRC emacs-lisp
(use-package neotree
  :after projectile
  :general
  (panda/general-leader "d" 'panda/neotree-toggle)
  :custom
  (neo-theme 'arrow)
  (neo-window-width 30)
  (neo-window-position 'left)
  :config
  (defun panda/neotree-toggle ()
    (interactive)
    (if (get-buffer-window " *NeoTree*" 'visible)
        (neotree-hide)
      (if (projectile-project-p)
          (neotree-dir (projectile-project-root))
        (neotree-show)))))
#+END_SRC
** Project
#+BEGIN_SRC emacs-lisp
(use-package projectile
  :general
  (panda/general-leader
    :prefix "j"
    :prefix-command 'projectile-command-map)
  :custom
  (projectile-indexing-method 'alien)
  (projectile-completion-system 'ivy)
  :config
  (projectile-mode))
#+END_SRC
** Window
*** Eyebrowse
Workspaces.
#+BEGIN_SRC emacs-lisp
(use-package eyebrowse
  :general
  (panda/general-leader
    "0" 'eyebrowse-switch-to-window-config-0
    "1" 'eyebrowse-switch-to-window-config-1
    "2" 'eyebrowse-switch-to-window-config-2
    "3" 'eyebrowse-switch-to-window-config-3
    "4" 'eyebrowse-switch-to-window-config-4
    "5" 'eyebrowse-switch-to-window-config-5
    "6" 'eyebrowse-switch-to-window-config-6
    "7" 'eyebrowse-switch-to-window-config-7
    "8" 'eyebrowse-switch-to-window-config-8
    "9" 'eyebrowse-switch-to-window-config-9)
  :config
  (eyebrowse-mode 1))
#+END_SRC
* Per-Language Packages
** Company
Activate auto-completion with ~company-mode~.
#+BEGIN_SRC emacs-lisp
(use-package company
  :general
  (general-def :keymaps 'company-active-map
    "<return>" 'company-complete-selection)
  :custom
  (company-dabbrev-code-modes nil)
  (company-idle-delay 0.1)
  (company-minimum-prefix-length 2)
  (company-tooltip-align-annotations t)
  :config
  (delete 'company-dabbrev company-backends))
#+END_SRC
** Format All
Auto-formats source files on save. Activate with ~format-all-mode~.
#+BEGIN_SRC emacs-lisp
(use-package format-all)
#+END_SRC
** Flycheck
Linting. Activate with ~flycheck-mode~.
#+BEGIN_SRC emacs-lisp
(use-package flycheck
  :general
  (panda/general-leader "e" 'panda/flycheck/body)
  :custom
  (flycheck-check-syntax-automatically '(mode-enabled save))
  :config
  (defhydra panda/flycheck (:hint nil :color pink)
    "
  flycheck
  [_p_]: previous error    [_n_]: next error    [_/_]: cancel"
    ("p" flycheck-previous-error)
    ("n" flycheck-next-error)
    ("/" (message "Abort") :color blue)))
#+END_SRC
** Lispy
Efficient lisp editing. Activate with ~lispy-mode~.

This might be confusing, but to enter brackets, type ~}~ instead of ~[~.
                                                                      #+BEGIN_SRC emacs-lisp
                                                                      (use-package lispy)

                                                                      (use-package lispyville
                                                                        :hook (lispy-mode . lispyville-mode))
                                                                      #+END_SRC
                                                                      ** Lsp
                                                                      Activate with ~lsp~.
                                                                      #+BEGIN_SRC emacs-lisp
                                                                      (use-package lsp-mode
                                                                        :custom
                                                                        (lsp-enable-indentation nil)
                                                                        (lsp-enable-on-type-formatting nil)
                                                                        (lsp-prefer-flymake nil)
                                                                        :config
                                                                        (require 'lsp-clients))

                                                                      (use-package company-lsp
                                                                        :after lsp-mode)

                                                                      (use-package lsp-ui
                                                                        :after lsp-mode)
                                                                      #+END_SRC
                                                                      ** Outshine
                                                                      Activate with ~outshine-mode~.
                                                                      #+BEGIN_SRC emacs-lisp
                                                                      (use-package outshine)
                                                                      #+END_SRC
                                                                      ** Yasnippet
                                                                      Code snippets. Activate with ~yas-minor-mode~.
                                                                      #+BEGIN_SRC emacs-lisp
                                                                      (use-package yasnippet
                                                                        :general
                                                                        (general-def :keymaps 'yas-minor-mode-map
                                                                          "<tab>" nil
                                                                          "TAB" nil
                                                                          "<backtab>" 'yas-expand)
                                                                        :custom
                                                                        (yas-triggers-in-field nil)
                                                                        (yas-indent-line 'auto)
                                                                        (yas-also-auto-indent-first-line t)
                                                                        :config
                                                                        (add-to-list 'yas-snippet-dirs (expand-file-name "snippets" user-emacs-directory))
                                                                        (yas-reload-all)
                                                                        (eval-after-load 'company
                                                                          (define-advice company-select-previous (:around (old-func &rest args))
                                                                            (unless (and (bound-and-true-p yas-minor-mode) (yas-expand))
                                                                              (call-interactively old-func args)))))

                                                                      (use-package yasnippet-snippets
                                                                        :after yasnippet)

                                                                      (use-package ivy-yasnippet
                                                                        :after yasnippet
                                                                        :general
                                                                        (panda/general-leader "y" 'ivy-yasnippet))
                                                                      #+END_SRC
                                                                      * Language Modes
                                                                      ** Assembly
                                                                      Used for GNU Assembler.

                                                                      Dependencies:
                                                                      - [[https://github.com/klauspost/asmfmt][asmfmt]]
                                                                      #+BEGIN_SRC emacs-lisp
                                                                      (defun panda/setup-asm-mode ()
                                                                        (format-all-mode 1)
                                                                        (yas-minor-mode 1)
                                                                        (setq indent-tabs-mode t)
                                                                        (setq-local tab-always-indent (default-value 'tab-always-indent)))

                                                                      (use-package asm-mode
                                                                        :custom
                                                                        (asm-comment-char ?#)
                                                                        :config
                                                                        (add-hook 'asm-mode-hook #'panda/setup-asm-mode))
                                                                      #+END_SRC
                                                                      ** C / C++
                                                                      Dependencies:
                                                                      - [[https://github.com/MaskRay/ccls][ccls]]
                                                                      - [[https://releases.llvm.org/download.html][clang-format]]
                                                                      #+BEGIN_SRC emacs-lisp
                                                                      (defun panda/setup-c-mode ()
                                                                        (yas-minor-mode 1)
                                                                        (c-set-style "linux")
                                                                        (c-set-offset 'inline-open 0)
                                                                        (c-set-offset 'innamespace 0)
                                                                        (setq c-basic-offset 4))

                                                                      (add-hook 'c-mode-hook #'panda/setup-c-mode)
                                                                      (add-hook 'c++-mode-hook #'panda/setup-c-mode)

                                                                      (use-package ccls
                                                                        :hook ((c-mode c++-mode) . lsp))

                                                                      (use-package clang-format
                                                                        :hook ((c-mode c++-mode) . panda/enable-clang-format)
                                                                        :config
                                                                        (defvar panda/clang-format-settings-file
                                                                          (expand-file-name "clang-format-defaults.json" user-emacs-directory)
                                                                          "A JSON file containing default clang-format settings.")
                                                                        (defun panda/default-clang-format-style ()
                                                                          "Reads the JSON file defined by `panda/clang-format-settings-file'"
                                                                          (with-temp-buffer
                                                                            (insert-file-contents panda/clang-format-settings-file)
                                                                            (let ((inhibit-message t))
                                                                              (replace-regexp "[\n\"]" ""))
                                                                            (buffer-string)))
                                                                        (defun panda/enable-clang-format ()
                                                                          (setq-local clang-format-style
                                                                                      (if (locate-dominating-file "." ".clang-format")
                                                                                          "file"
                                                                                        (panda/default-clang-format-style)))
                                                                          (add-hook 'before-save-hook #'clang-format-buffer nil t)))
                                                                      #+END_SRC
                                                                      ** C#
                                                                      Dependencies:
                                                                      - [[https://github.com/OmniSharp/omnisharp-roslyn][omnisharp-roslyn server]]
                                                                      - can be installed with ~M-x omnisharp-install-server~
                                                                      #+BEGIN_SRC emacs-lisp
                                                                      (defun panda/setup-csharp-mode ()
                                                                        (company-mode 1)
                                                                        (flycheck-mode 1)
                                                                        (yas-minor-mode 1)
                                                                        (add-hook 'before-save-hook #'delete-trailing-whitespace nil t))

                                                                      (use-package csharp-mode
                                                                        :config
                                                                        (add-hook 'csharp-mode-hook #'panda/setup-csharp-mode))

                                                                      (use-package omnisharp
                                                                        :init
                                                                        (add-hook 'csharp-mode-hook #'omnisharp-mode)
                                                                        :config
                                                                        (add-to-list 'company-backends 'company-omnisharp))
                                                                      #+END_SRC
                                                                      ** CMake
                                                                      #+BEGIN_SRC emacs-lisp
                                                                      (defun panda/setup-cmake-mode ()
                                                                        (yas-minor-mode 1)
                                                                        (add-hook 'before-save-hook #'delete-trailing-whitespace))

                                                                      (use-package cmake-mode
                                                                        :config
                                                                        (add-hook 'cmake-mode-hook #'panda/setup-cmake-mode))
                                                                      #+END_SRC
                                                                      ** Clojure
                                                                      Java hell. Activate cider with ~M-x cider-jack-in~. No hook is added because cider start-up can be slow.

                                                                      Dependencies:
                                                                      - [[https://github.com/technomancy/leiningen][leiningen]] or [[https://github.com/boot-clj/boot][boot]]
                                                                      #+BEGIN_SRC emacs-lisp
                                                                      (defun panda/setup-clojure-mode ()
                                                                        (lispy-mode 1)
                                                                        (yas-minor-mode 1)
                                                                        (add-hook 'before-save-hook #'delete-trailing-whitespace nil t))

                                                                      (use-package clojure-mode
                                                                        :config
                                                                        (add-hook 'clojure-mode-hook #'panda/setup-clojure-mode))

                                                                      (use-package cider
                                                                        :config
                                                                        (add-hook 'cider-mode-hook (lambda ()
                                                                                                     (interactive)
                                                                                                     (company-mode 1)
                                                                                                     (add-hook 'before-save-hook #'cider-format-buffer nil t))))
                                                                      #+END_SRC
                                                                      ** Common Lisp
                                                                      Dependencies:
                                                                      - [[http://www.sbcl.org/platform-table.html][sbcl]]
                                                                      #+BEGIN_SRC emacs-lisp
                                                                      (defun panda/setup-slime-mode ()
                                                                        (lispy-mode 1)
                                                                        (yas-minor-mode 1)
                                                                        (add-hook 'before-save-hook #'delete-trailing-whitespace nil t))

                                                                      (use-package slime
                                                                        :config
                                                                        (add-hook 'slime-mode-hook #'panda/setup-slime-mode)
                                                                        (setq inferior-lisp-program (executable-find "sbcl"))
                                                                        (slime-setup '(slime-fancy)))
                                                                      #+END_SRC
                                                                      ** Emacs Lisp
                                                                      #+BEGIN_SRC emacs-lisp
                                                                      (defun panda/setup-emacs-lisp-mode ()
                                                                        (company-mode 1)
                                                                        (format-all-mode 1)
                                                                        (lispy-mode 1)
                                                                        (yas-minor-mode 1))

                                                                      (add-hook 'emacs-lisp-mode-hook #'panda/setup-emacs-lisp-mode)
                                                                      #+END_SRC
                                                                      ** Git Files
                                                                      #+BEGIN_SRC emacs-lisp
                                                                      (defun panda/setup-gitfiles-mode ()
                                                                        (yas-minor-mode 1)
                                                                        (add-hook 'before-save-hook #'delete-trailing-whitespace nil t))

                                                                      (use-package gitattributes-mode
                                                                        :config
                                                                        (add-hook 'gitattributes-mode-hook #'panda/setup-gitfiles-mode))

                                                                      (use-package gitconfig-mode
                                                                        :config
                                                                        (add-hook 'gitconfig-mode-hook #'panda/setup-gitfiles-mode))

                                                                      (use-package gitignore-mode
                                                                        :config
                                                                        (add-hook 'gitignore-mode-hook #'panda/setup-gitfiles-mode))
                                                                      #+END_SRC
                                                                      ** Go
                                                                      Dependencies:
                                                                      - [[https://github.com/nsf/gocode][gocode]]
                                                                      - [[https://golang.org/cmd/gofmt/][gofmt]]
                                                                      #+BEGIN_SRC emacs-lisp
                                                                      (defun panda/setup-go-mode ()
                                                                        (company-mode 1)
                                                                        (flycheck-mode 1)
                                                                        (format-all-mode 1)
                                                                        (yas-minor-mode 1)
                                                                        (setq indent-tabs-mode t))

                                                                      (use-package go-mode
                                                                        :config
                                                                        (add-hook 'go-mode-hook #'panda/setup-go-mode))

                                                                      (use-package go-eldoc
                                                                        :config
                                                                        (add-hook 'go-mode-hook 'go-eldoc-setup))

                                                                      (use-package company-go
                                                                        :config
                                                                        (add-to-list 'company-backends 'company-go))
                                                                      #+END_SRC
                                                                      ** Haskell
                                                                      Dependencies:
                                                                      - [[https://docs.haskellstack.org/en/stable/install_and_upgrade/][stack]]
                                                                      - [[https://github.com/lspitzner/brittany][brittany]]
                                                                      #+BEGIN_SRC emacs-lisp
                                                                      (defun panda/setup-haskell-mode ()
                                                                        (company-mode 1)
                                                                        (flycheck-mode 1)
                                                                        (format-all-mode 1)
                                                                        (yas-minor-mode 1))

                                                                      (use-package haskell-mode
                                                                        :config
                                                                        (add-hook 'haskell-mode-hook #'panda/setup-haskell-mode))

                                                                      (use-package intero
                                                                        :init
                                                                        (add-hook 'haskell-mode-hook #'intero-mode)
                                                                        :config
                                                                        (flycheck-add-next-checker 'intero '(info . haskell-hlint)))
                                                                      #+END_SRC
                                                                      ** HTML / PHP / ASP.NET / Embedded Ruby
                                                                      #+BEGIN_SRC emacs-lisp
                                                                      (defun panda/setup-web-mode ()
                                                                        (yas-minor-mode 1)
                                                                        (add-hook 'before-save-hook #'delete-trailing-whitespace nil t))

                                                                      (use-package web-mode
                                                                        :mode (("\\.php\\'" . web-mode)
                                                                               ("\\.as[cp]x\\'" . web-mode)
                                                                               ("\\.erb\\'" . web-mode)
                                                                               ("\\.html?\\'" . web-mode))
                                                                        :config
                                                                        (add-hook 'web-mode-hook #'panda/setup-web-mode)
                                                                        (setq web-mode-markup-indent-offset 2
                                                                              web-mode-style-padding 4
                                                                              web-mode-script-padding 4
                                                                              web-mode-block-padding 4))
                                                                      #+END_SRC
                                                                      ** Java
                                                                      ~panda/enable-clang-format~ is defined under the C/C++ section.

                                                                      Dependencies
                                                                      - [[https://releases.llvm.org/download.html][clang-format]]
                                                                      #+BEGIN_SRC emacs-lisp
                                                                      (defun panda/setup-java-mode ()
                                                                        (yas-minor-mode 1)
                                                                        (panda/enable-clang-format))

                                                                      (add-hook 'java-mode-hook #'panda/setup-java-mode)
                                                                      #+END_SRC
                                                                      ** JavaScript
                                                                      ~panda/enable-clang-format~ is defined under the C/C++ section.

                                                                      Dependencies:
                                                                      - [[https://www.npmjs.com/package/tern][tern]]
                                                                      - [[https://releases.llvm.org/download.html][clang-format]]
                                                                      #+BEGIN_SRC emacs-lisp
                                                                      (defun panda/setup-javascript-mode ()
                                                                        (company-mode 1)
                                                                        (flycheck-mode 1)
                                                                        (yas-minor-mode 1)
                                                                        (panda/enable-clang-format))

                                                                      (use-package js2-mode
                                                                        :mode (("\\.js\\'" . js2-mode))
                                                                        :config
                                                                        (add-hook 'js2-mode-hook #'panda/setup-javascript-mode))

                                                                      (use-package tern
                                                                        :init
                                                                        (add-hook 'js2-mode-hook #'tern-mode))

                                                                      (use-package company-tern
                                                                        :after tern
                                                                        :config
                                                                        (add-to-list 'company-backends 'company-tern))
                                                                      #+END_SRC
                                                                      ** Latex
                                                                      #+BEGIN_SRC emacs-lisp
                                                                      (defun panda/setup-latex-mode ()
                                                                        (yas-minor-mode 1)
                                                                        (add-hook 'before-save-hook #'delete-trailing-whitespace nil t))

                                                                      (add-hook 'LaTeX-mode-hook #'panda/setup-latex-mode)

                                                                      (use-package tex
                                                                        :ensure auctex
                                                                        :custom
                                                                        (TeX-auto-save t)
                                                                        (TeX-parse-self t))
                                                                      #+END_SRC
                                                                      ** Makefile
                                                                      #+BEGIN_SRC emacs-lisp
                                                                      (defun panda/setup-makefile-mode ()
                                                                        (add-hook 'before-save-hook #'delete-trailing-whitespace nil t))

                                                                      (add-hook 'makefile-mode-hook #'panda/setup-makefile-mode)
                                                                      #+END_SRC
                                                                      ** Markdown
                                                                      Dependencies:
                                                                      - [[https://prettier.io/docs/en/install.html][prettier]]
                                                                      #+BEGIN_SRC emacs-lisp
                                                                      (defun panda/setup-markdown-mode ()
                                                                        (format-all-mode 1)
                                                                        (yas-minor-mode 1))

                                                                      (use-package markdown-mode
                                                                        :config
                                                                        (add-hook 'markdown-mode-hook #'panda/setup-markdown-mode))
                                                                      #+END_SRC
                                                                      ** Org
                                                                      #+BEGIN_SRC emacs-lisp
                                                                      (defun panda/setup-org-mode ()
                                                                        (add-hook 'before-save-hook #'delete-trailing-whitespace nil t))

                                                                      (use-package org
                                                                        :config
                                                                        (add-hook 'org-mode-hook #'panda/setup-org-mode)
                                                                        (setq org-src-fontify-natively t
                                                                              org-src-tab-acts-natively t))

                                                                      (use-package evil-org
                                                                        :config
                                                                        (add-hook 'org-mode-hook #'evil-org-mode)
                                                                        (add-hook 'evil-org-mode-hook
                                                                                  (lambda () (evil-org-set-key-theme))))
                                                                      #+END_SRC
                                                                      ** PowerShell
                                                                      #+BEGIN_SRC emacs-lisp
                                                                      (defun panda/setup-powershell-mode ()
                                                                        (yas-minor-mode 1)
                                                                        (add-hook 'before-save-hook #'delete-trailing-whitespace nil t))

                                                                      (use-package powershell
                                                                        :config
                                                                        (add-hook 'powershell-mode-hook #'panda/setup-powershell-mode))
                                                                      #+END_SRC
                                                                      ** Python
                                                                      Dependencies:
                                                                      - [[https://pypi.org/project/setuptools/][setuptools]]
                                                                      - [[https://flake8.readthedocs.io/en/latest/][flake8]] or [[https://pylint.org/#install][pylint]]
                                                                      - [[https://github.com/ambv/black][black]]
                                                                      #+BEGIN_SRC emacs-lisp
                                                                      (defun panda/setup-python-mode ()
                                                                        (company-mode 1)
                                                                        (flycheck-mode 1)
                                                                        (yas-minor-mode 1)
                                                                        (setq-local yas-indent-line 'fixed)
                                                                        (setq-local yas-also-auto-indent-first-line nil))

                                                                      (use-package python
                                                                        :config
                                                                        (add-hook 'python-mode-hook #'panda/setup-python-mode)
                                                                        (setq python-indent-offset 4))

                                                                      (use-package blacken
                                                                        :hook (python-mode . blacken-mode)
                                                                        :custom
                                                                        (blacken-line-length 80))

                                                                      (use-package anaconda-mode
                                                                        :init
                                                                        (add-hook 'python-mode-hook #'anaconda-mode)
                                                                        (add-hook 'python-mode-hook #'anaconda-eldoc-mode))

                                                                      (use-package company-anaconda
                                                                        :after anaconda-mode
                                                                        :config
                                                                        (add-to-list 'company-backends 'company-anaconda))
                                                                      #+END_SRC
                                                                      ** R
                                                                      #+BEGIN_SRC emacs-lisp
                                                                      (defun panda/setup-r-mode ()
                                                                        (company-mode 1)
                                                                        (yas-minor-mode 1)
                                                                        (add-hook 'before-save-hook #'delete-trailing-whitespace nil t))

                                                                      (use-package ess
                                                                        :commands R
                                                                        :config
                                                                        (add-hook 'ess-r-mode-hook #'panda/setup-r-mode))
                                                                      #+END_SRC
                                                                      ** Rust
                                                                      Dependencies:
                                                                      - [[https://www.rust-lang.org/en-US/install.html][cargo]]
                                                                      - [[https://github.com/racer-rust/racer][racer]]
                                                                      - [[https://github.com/rust-lang-nursery/rustfmt][rustfmt]]
                                                                      #+BEGIN_SRC emacs-lisp
                                                                      (defun panda/setup-rust-mode ()
                                                                        (company-mode 1)
                                                                        (if (locate-dominating-file default-directory "Cargo.toml")
                                                                            (flycheck-mode 1))
                                                                        (yas-minor-mode 1)
                                                                        (add-hook 'before-save-hook #'delete-trailing-whitespace nil t))

                                                                      (use-package rust-mode
                                                                        :config
                                                                        (add-hook 'rust-mode-hook #'panda/setup-rust-mode)
                                                                        (setq rust-format-on-save t))

                                                                      (use-package cargo
                                                                        :init
                                                                        (add-hook 'rust-mode-hook #'cargo-minor-mode))

                                                                      (use-package racer
                                                                        :init
                                                                        (add-hook 'rust-mode-hook #'racer-mode))

                                                                      (use-package flycheck-rust
                                                                        :init
                                                                        (add-hook 'rust-mode-hook #'flycheck-rust-setup))
                                                                      #+END_SRC
                                                                      ** TypeScript
                                                                      Dependencies:
                                                                      - [[https://www.typescriptlang.org/#download-links][tsc]]
                                                                      - [[https://nodejs.org/en/][node.js]]
                                                                      #+BEGIN_SRC emacs-lisp
                                                                      (defun panda/setup-typescript-mode ()
                                                                        (company-mode 1)
                                                                        (flycheck-mode 1)
                                                                        (yas-minor-mode 1))

                                                                      (use-package typescript-mode
                                                                        :config
                                                                        (add-hook 'typescript-mode-hook #'panda/setup-typescript-mode))

                                                                      (use-package tide
                                                                        :init
                                                                        (defun setup-tide-mode ()
                                                                          (interactive)
                                                                          (tide-setup)
                                                                          (tide-hl-identifier-mode +1)
                                                                          (add-hook 'before-save-hook #'tide-format-before-save nil t))
                                                                        (add-hook 'typescript-mode-hook #'setup-tide-mode))
                                                                      #+END_SRC

                                                                      (defconst org-config-path
                                                                        (expand-file-name "config.org" user-emacs-directory))

                                                                      (defconst el-config-path
                                                                        (expand-file-name "config.el" user-emacs-directory))

                                                                      (if (file-newer-than-file-p org-config-path el-config-path)
                                                                          (org-babel-load-file org-config-path)
                                                                        (load-file el-config-path))

                                                                      (provide 'init)
;;; init.el ends here
