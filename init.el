;;; init.el --- panda's emacs init.el file

;;; Commentary:
;;; pls shut up flycheck

;;; Code:

(require 'package)
(add-to-list 'package-archives '("melpa" . "http://melpa.milkbox.net/packages/") t)

(defvar panda/packages
  '(ample-theme
    atom-one-dark-theme
    clojure-mode
    csharp-mode
    esup
    fireplace
    haskell-mode
    hydra
    monokai-theme
    pacmacs
    solarized-theme
    spacemacs-theme
    typescript-mode
    use-package
    zenburn-theme))

(setq package-enable-at-startup nil) ;so it doesn't run twice
(package-initialize)

(unless package-archive-contents ;refresh package list if it's empty
  (package-refresh-contents))

(defun panda/ensure-packages (packages)
  "PACKAGES Shut up flycheck."
  (let ((refreshed? nil))
    (dolist (package packages)
      (unless (package-installed-p package)
        (unless refreshed?
          (package-refresh-contents)
          (setq refreshed? t))
        (package-install package)))))

(panda/ensure-packages panda/packages)

(setq custom-file "~/.emacs.d/custom-file.el") ;separate file for custom.el
(load custom-file 'noerror)

(global-auto-revert-mode t) ;reloads file if changed externally
(set-frame-font "Consolas-10") ;why emacs keep resetting my font
(setq disabled-command-function nil)
(add-hook 'before-save-hook 'delete-trailing-whitespace) ;self-explanatory

(load "server") ;emacsclient server
(unless (server-running-p)
  (server-start))

(load-theme 'monokai t)

(require 'use-package)
(setq use-package-always-ensure t)

(use-package ace-window
  :bind (("C-x o" . ace-window)))

(use-package avy
  :bind (("C-c a" . avy-goto-word-1))
  :config
  (defun panda/change-avy-faces ()
  (dolist (avy-face avy-lead-faces)
    (set-face-attribute avy-face nil
                        :background (face-attribute 'default :background)
                        :weight 'bold))
  (set-face-attribute 'avy-lead-face nil
                      :foreground "#39FF14")
  (set-face-attribute 'avy-lead-face-0 nil
                      :foreground "#67C8FF")
  (set-face-attribute 'avy-lead-face-1 nil ;this face isn't even used
                      :foreground "#BF5FFF")
  (set-face-attribute 'avy-lead-face-2 nil
                      :foreground "#FF9933"))
  (panda/change-avy-faces)
  (setq avy-background t))

(use-package company
  :init
  (add-hook 'after-init-hook 'global-company-mode)
  :config
  (setq company-idle-delay 0.1
        company-minimum-prefix-length 1
        company-tooltip-align-annotations t))

(use-package expand-region
  :bind (("C-;" . er/expand-region)))

(use-package flycheck
  :init
  (add-hook 'after-init-hook #'global-flycheck-mode)
  :config
  (setq flycheck-check-syntax-automatically '(mode-enabled save idle-change new-line)))

(use-package god-mode
  :bind (("C-c e" . panda/god-mode)
         :map god-local-mode-map
         ("C-x C-b" . ido-switch-buffer)
         ("C-x C-o" . ace-window)
         ("C-x C-0" . delete-window)
         ("C-x C-1" . delete-other-windows)
         ("C-x C-2" . split-window-below)
         ("C-x C-3" . split-window-right)
         ("C-c C-a" . avy-goto-word-1)
         ("C-c C-e" . panda/god-mode)
         ("C-c C-n" . nlinum-mode)
         ("C-c C-o C-o" . origami-toggle-node)
         ("C-c C-o C-a" . origami-toggle-all-nodes)
         ("C-c C-o C-p" . origami-show-only-node)
         ("C-c C-p C-f" . projectile-find-file)
         ("C-c C-p C-k" . projectile-kill-buffers)
         ("C-c C-p C-p" . projectile-switch-project))
  :init
  (defvar panda/emacs-cursor (face-attribute 'cursor :background))
  (defvar panda/god-cursor "magenta")
  (defun panda/god-mode()
    (interactive)
    (god-mode-all)
    (if (bound-and-true-p god-local-mode)
        (set-cursor-color panda/god-cursor)
      (set-cursor-color panda/emacs-cursor))))

(use-package ido
  :init
  (ido-mode t)
  (ido-everywhere t))

(use-package ido-vertical-mode
  :init
  (ido-vertical-mode t)
  :config
  (setq ido-vertical-define-keys 'C-n-and-C-p-only))

(use-package ido-ubiquitous
  :init
  (ido-ubiquitous-mode t))

(use-package magit
  :bind (("C-c g" . magit-status)))

(use-package multiple-cursors
  :init
  (defhydra hydra-multiple-cursors (global-map "C-c m")
    ("p" mc/mark-previous-like-this)
    ("n" mc/mark-next-like-this)
    ("l" mc/edit-lines)
    ("a" mc/mark-all-like-this :exit t)
    ("q" nil)))

(use-package nlinum
  :bind (("C-c n" . nlinum-mode)))

(use-package origami
  :bind (:map origami-mode-map
              ("C-c o o" . origami-toggle-node)
              ("C-c o a" . origami-toggle-all-nodes)
              ("C-c o p" . origami-show-only-node))
  :init
  (global-origami-mode))

(use-package projectile
  :init
  (projectile-mode)
  :config
  (setq projectile-indexing-method 'alien))

(use-package rainbow-delimiters
  :init
  (add-hook 'prog-mode-hook #'rainbow-delimiters-mode))

(use-package smart-mode-line
  :config
  (setq sml/no-confirm-load-theme t
        sml/name-width 0)
  (sml/setup))

(use-package smex
  :bind (("M-x" . smex))
  :init
  (smex-initialize))

(use-package undo-tree
  :bind (:map undo-tree-map
              ("C-." . undo-tree-redo)
              ("C-?" . nil))
  :init
  (global-undo-tree-mode))

(use-package winner
  :init
  (winner-mode t))

(use-package yasnippet
  :init
  (yas-global-mode t)
  :config
  (setq-default yas-snippet-dirs '("~/.emacs.d/snippets"))
  (yas-reload-all)
  (setq yas-triggers-in-field t
        yas-indent-line 'auto
        yas-also-auto-indent-first-line t)
  (defun company-yasnippet-or-completion ()
    (interactive)
    (let ((yas-fallback-behavior nil))
      (unless (yas-expand)
        (call-interactively #'company-complete-common))))
  (defun company-yas-tab ()
    (substitute-key-definition 'company-complete-common
                               'company-yasnippet-or-completion
                               company-active-map))
  (add-hook 'company-mode-hook #'company-yas-tab))

(use-package irony
  :defer t
  :init
  (add-hook 'c-mode-hook 'irony-mode)
  (add-hook 'c++-mode-hook 'irony-mode)
  :config
  (defun my-irony-mode-hook ()
    (define-key irony-mode-map [remap completion-at-point]
      'irony-completion-at-point-async)
    (define-key irony-mode-map [remap complete-symbol]
      'irony-completion-at-point-async))
  (add-hook 'irony-mode-hook 'my-irony-mode-hook)
  (add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options)
  (when (boundp 'w32-pipe-read-delay)
    (setq w32-pipe-read-delay 0))
  (when (boundp 'w32-pipe-buffer-size)
    (setq irony-server-w32-pipe-buffer-size (* 64 1024))))

(use-package company-irony
  :after (company company-irony-c-headers irony)
  :config
  (add-to-list 'company-backends 'company-irony))

(use-package flycheck-irony
  :after (flycheck irony)
  :config
  (add-hook 'flycheck-mode-hook #'flycheck-irony-setup))

(use-package company-irony-c-headers
  :after (company irony)
  :config
  (add-to-list 'company-backends 'company-irony-c-headers))

(use-package omnisharp
  :defer t
  :init
  (add-hook 'csharp-mode-hook 'omnisharp-mode)
  :config
  (setq omnisharp-server-executable-path
        "~/.emacs.d/omnisharp-roslyn/artifacts/publish/OmniSharp/default/net46/omnisharp.exe")
  (eval-after-load 'company
    '(add-to-list 'company-backends 'company-omnisharp)))

(use-package anaconda-mode
  :defer t
  :init
  (add-hook 'python-mode-hook 'anaconda-mode)
  (add-hook 'python-mode-hook 'anaconda-eldoc-mode))

(use-package company-anaconda
  :after (anaconda company)
  :config
  (add-to-list 'company-backends 'company-anaconda))

(use-package tide
  :defer t
  :init
  (defun setup-tide-mode ()
    (interactive)
    (tide-setup)
    (eldoc-mode +1)
    (tide-hl-identifier-mode +1))
  (add-hook 'before-save-hook 'tide-format-before-save)
  (add-hook 'typescript-mode-hook #'setup-tide-mode))

(use-package web-mode
  :defer t
  :mode (("\\.php\\'" . web-mode)
         ("\\.as[cp]x\\'" . web-mode)
         ("\\.erb\\'" . web-mode)
         ("\\.html?\\'" . web-mode))
  :config
  (setq web-mode-markup-indent-offset 2
        web-mode-style-padding 4
        web-mode-script-padding 4
        web-mode-block-padding 4))

(w32-send-sys-command 61488) ;fullscreen

(provide 'init)
