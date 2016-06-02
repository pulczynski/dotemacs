;;; init.el --- Global settings -*- lexical-binding: t; -*-

;;; Commentary:

;; This is the bootstrap code for geting the literate configuration file in =config.org= up and running. The original source for much of this code is from sriramkswamy/dotemacs at =https://github.com/sriramkswamy/dotemacs=.  

;;; Code:

;; Increase the garbage collection threshold to 500 MB to ease startup
(setq gc-cons-threshold (* 500 1024 1024))

;; Show elapsed start-up time in mini-buffer
(let ((emacs-start-time (current-time)))
  (add-hook 'emacs-startup-hook
            (lambda ()
              (let ((elapsed (float-time (time-subtract (current-time) emacs-start-time))))
                (message "[Emacs initialized in %.3fs]" elapsed)))))

;; List package archives and initialize them
(require 'package)
(when (>= emacs-major-version 24)
  (require 'package)
  (add-to-list 'package-archives '("melpa" . "http://melpa.milkbox.net/packages/") t)
  (add-to-list 'package-archives '("org" . "http://orgmode.org/elpa/") t))
(when (< emacs-major-version 24)
  ;; For important compatibility libraries like cl-lib
  (add-to-list 'package-archives '("gnu" . "http://elpa.gnu.org/packages/")))
(package-initialize)

;; Make sure Org is installed
(unless (package-installed-p 'org)
    (package-refresh-contents)
    (package-install 'org))

;; Org plus contrib needs to be loaded before any org related functionality is called
(unless (package-installed-p 'org-plus-contrib)
    (package-refresh-contents)
    (package-install 'org-plus-contrib))

;; Check if use-package is installed, and install if not. Then require it.
(unless (package-installed-p 'use-package)
    (package-refresh-contents)
    (package-install 'use-package))

(eval-when-compile
  (require 'use-package))
(require 'bind-key)                ;; if you use any :bind variant
(require 'diminish)                ;; if you use diminish

;; load config -- Note that config file must exist & have source code for tangling, otherwise errors get thrown!!
(defvar init-source-org-file (expand-file-name "config.org" user-emacs-directory)
  "The file that our emacs initialization comes from")

(defvar init-source-el-file (expand-file-name "config.el" user-emacs-directory)
  "The file that our emacs initialization is generated into")

(if (file-exists-p init-source-org-file)
    (if (and (file-exists-p init-source-el-file)
             (time-less-p (nth 5 (file-attributes init-source-org-file)) (nth 5 (file-attributes init-source-el-file))))
        (load-file init-source-el-file)
      (if (fboundp 'org-babel-load-file)  
          (org-babel-load-file init-source-org-file)
        (message "Function not found: org-babel-load-file")
        (load-file init-source-el-file)))
  (error "Init org file '%s' missing." init-source-org-file))

;; Garbage collector - decrease threshold to 5 MB
(add-hook 'after-init-hook (lambda () (setq gc-cons-threshold (* 5 1024 1024))))
  ;;; init.el ends here
