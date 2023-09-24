;; Author: J. Dylan White
;; Description: Website build script
;; Note: This script is run with the -Q flag which ignores any configuration
;;       and any custom variables

;; Load the publishing system
;; This generate the HTML output from org-mode documents`'
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
(package-install 'htmlize)

;; Customize the HTML output
(setq
 ;; Don't add the HTML Validate link at the bottom of our published page
 org-html-validation-link nil            ;; Don't show validation link
 ;; Don't add the default JavaScript
 org-html-head-include-scripts nil
 ;; Don't use the default styles
 org-html-head-include-default-style nil
 ;; Use a pre-built CSS
 org-html-head "<link rel=\"stylesheet\" href=\"https://cdn.simplecss.org/simple.min.css\" />")

;; Set the project to publish upon running this script as well as how
;; to publish them
(setq org-publish-project-alist
      (list
       (list "website"
             ;; Publish all files in the base directory
             :recursive t
             ;; Where the org-mode files are located
             :base-directory "./content"
             ;; Where the HTML files are generated
             :publishing-directory "./public"
             ;; Function to convert org-mode to desired format
             :publishing-function 'org-html-publish-to-html
             ;; Don't show the author in the footer
             :with-author nil
             ;; Add that site was generated with Emacs org-mode in footer
             :with-creator t
             ;; Don't add the table of contents
             :with-toc nil
             ;; Don't add section numbers in the headings
             :section-numbers nil
             ;; Don't include a time-stamp in the file
             :time-stamp-file nil)))

;; Generate the site output
(org-publish-all t)

(message "Build complete!")
