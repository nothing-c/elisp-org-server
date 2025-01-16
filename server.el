(require 'web-server)
(defvar eos-port 9000)			;Temporary

(defvar eos-handlers
  '(((:GET . "/foo") . eos-index)
    ((:GET . "\.org") . eos-org-file)
    ))

(defun eos-index (request)
  "Generate tmp index.html"
  (with-slots (process headers) request
    (ws-response-header process 200 '("Content-type" . "text/html"))
    (process-send-string (process request) "<html><head>Index</head><body><p>Hi!</p></body></html>")))

(defun eos-org-file (request)
  "Generate and serve an org-mode file"
  (with-slots (process headers) request
    (ws-response-header process 200 '("Content-type" . "text/html"))
    (process-send-string (process request) (eos-render-org-file (eos-get-file headers)))))

(defun eos-get-file (headers)
  "Get the name of the requested file"
  "./elisp-org-server.org")		; Temporary

(defun eos-render-org-file (file)
  "Render an org file into a string of HTML"
  (with-temp-buffer
    (insert-file-contents file)
    (org-export-to-buffer 'html "*auto-org-export*" '() '() '() t)
    (buffer-string)))


;; (ws-start				; Working
;;  (lambda (request)
;;    (with-slots (process headers) request
;;      (ws-response-header process 200 '("Content-type" . "text/plain"))
;;      (process-send-string process "hello world")))
;;  9000)

(defun eos-run ()
  "Run the elisp org server (name not final)"
  (ws-start eos-handlers eos-port))

(eos-run)
