;; Author: J. Dylan White
;; Description: Website build script
;; Note: This script is run with the -Q flag which ignores any configuration
;;       and any custom variables

;; Load the publishing system
;; This generates the HTML output from org-mode documents
(require 'ox-publish)

;; Set the package installation directory so that packages aren't stored in
;; the ~/.emacs.d/elpa path.
(require 'package)
(setq package-user-dir (expand-file-name "./.packages"))
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("elpa" . "https://elpa.gnu.org/packages/")))

;; Initialize the package system
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

;; Install dependencies
;; hmtlize is necessary for code syntax highlighting
(package-install 'htmlize)

;; Customize the HTML output
(setq org-html-validation-link nil
      org-html-head-include-scripts nil
      org-html-head-include-default-style nil
      org-html-head "<link rel=\"stylesheet\" href=\"https://cdn.simplecss.org/simple.min.css\" />")

;; Set the project to publish upon running this script as well as how
;; to publish them
(setq org-publish-project-alist
      (list
       (list "website"
             :recursive t
             :base-directory "./content"
             :base-extension "org"
             :publishing-directory "./public"
             :publishing-function 'org-html-publish-to-html
             :with-author nil
             :with-title nil
             :with-creator t
             :with-toc nil
             :section-numbers nil
             :time-stamp-file nil)))

;; Generate the site output
(org-publish-all t)

;; Send a completion message
(message "Build complete!")
