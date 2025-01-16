(require 'web-server)
(defvar eos-port 9000)			;Temporary

(defvar eos-handlers
  '(((:GET . "/foo") . eos-index)
    ))

(defun eos-index (request)
  "Generate tmp index.html"
  (with-slots (process headers) request
    (ws-response-header process 200 '("Content-type" . "text/html"))
    (process-send-string (process request) "<html><head>Index</head><body><p>Hi!</p></body></html>")))


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
