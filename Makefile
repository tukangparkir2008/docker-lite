APP_DIR := ./app
TMP_DIR := /tmp/jibas_install
JIBAS_SRC_URL := https://jibas.id/res/jibas/jibas.src-33.0.7z
JIBAS_ARCHIVE_NAME := jibas.src-33.0.7z
JIBAS_DIR := jibas-33.0
SQL_FILE_NAME := jibas_db.sql
# Path lengkap ke file SQL
SQL_FULL_PATH := $(APP_DIR)/$(SQL_FILE_NAME)
CONFIG_DB_FILE := $(APP_DIR)/jibas/include/database.config.php
CONFIG_APP_FILE := $(APP_DIR)/jibas/include/application.config.php
CONFIG_SCH_FILE := $(APP_DIR)/jibas/include/school.config.php
CONFIG_SHARE_FILE:= $(APP_DIR)/jibas/include/filesharing.config.php

# Variabel koneksi database (sebaiknya diambil dari .env atau konfigurasi aplikasi)
# Menggunakan $(strip ...) untuk membersihkan spasi ekstra dari nilai .env
DB_HOST := 127.0.0.1
DB_PORT := $(strip $(shell grep DB_PORT .env | cut -d '=' -f2))
DB_NAME := $(strip $(shell grep DB_DATABASE .env | cut -d '=' -f2))
DB_USER := $(strip $(shell grep DB_USERNAME .env | cut -d '=' -f2))
DB_ROOT_PASS := $(strip $(shell grep DB_ROOT_PASSWORD .env | cut -d '=' -f2))

SEKOLAH := $(shell grep SEKOLAH .env | cut -d '=' -f2 | tr -d '\r')
YAYASAN := $(shell grep YAYASAN .env | cut -d '=' -f2 | tr -d '\r')
ALAMAT  := $(shell grep ALAMAT .env | cut -d '=' -f2 | tr -d '\r')

DOMAIN  := $(shell grep DOMAIN .env | cut -d '=' -f2 | tr -d '\r')
DOMAINHTTPS  := $(shell grep DOMAINHTTPS .env | cut -d '=' -f2 | tr -d '\r')

# Target default
all: install

# Target untuk membersihkan hasil download dan instalasi sementara
clean:
	@echo "Membersihkan direktori sementara..."
	@rm -rf $(TMP_DIR)
	@echo "Selesai."

# Target untuk mengunduh dan mengekstrak source code JIBAS
download-extract: clean
	@echo "Membuat direktori sementara: $(TMP_DIR)"
	@mkdir -p $(TMP_DIR)
	@echo "Mengunduh JIBAS versi $(JIBAS_VERSION) dari $(JIBAS_SRC_URL)..."
	@wget --no-check-certificate -O $(TMP_DIR)/$(JIBAS_ARCHIVE_NAME) $(JIBAS_SRC_URL)
	@echo "Mengekstrak $(JIBAS_ARCHIVE_NAME) ke $(TMP_DIR)..."
	@7z x -y -o$(TMP_DIR) $(TMP_DIR)
	@echo "Ekstraksi selesai."

# Target untuk menyalin file aplikasi ke direktori tujuan
copy-app: download-extract
	@echo "Menyalin file aplikasi dari $(TMP_DIR)/$(JIBAS_DIR)/ ke $(APP_DIR)/..."
	# Pastikan JIBAS_EXTRACTED_DIR_NAME sesuai dengan nama folder setelah 7z mengekstrak
	@cp -r $(TMP_DIR)/$(JIBAS_DIR)/* $(APP_DIR)/
	@echo "Penyalinan file aplikasi selesai."

# Target untuk mengatur hak akses
# Variabel untuk User dan Group Web Server (biasanya www-data)
WEB_USER_GROUP := www

set-permissions:
	@echo "Mengatur hak akses di $(APP_DIR)..."
	
	# 1. Ubah kepemilikan semua file ke user saat ini dan group web server
	@sudo chown -R $(shell whoami):$(WEB_USER_GROUP) $(APP_DIR)
	# 2. Atur permission standar (Folder: 755, File: 644)
	@find $(APP_DIR) -type d -exec chmod 755 {} \;
	@find $(APP_DIR) -type f -exec chmod 644 {} \;

	@echo "Pengaturan hak akses untuk $(WEB_USER_GROUP) selesai."


# Target untuk setup database
# komentari jika tidak ingin menggunakan database
setup-database:
	@echo "Memulai setup database..."
	@if [ ! -f "$(SQL_FULL_PATH)" ]; then \
		echo "ERROR: File SQL '$(SQL_FULL_PATH)' tidak ditemukan!"; \
		exit 1; \
	fi
	@echo "Mengimpor skema database dari $(SQL_FULL_PATH) menggunakan user root..."
	@mysql -h "$(DB_HOST)" -P "$(DB_PORT)" -u root -p"$(DB_ROOT_PASS)" < "$(SQL_FULL_PATH)"
	@echo "Setup database selesai."
	

# Target untuk membuat/memperbarui file konfigurasi database aplikasi

config:
	@echo "Membuat file konfigurasi..."
	
	# Membuat config database
	# Menggunakan $$ untuk variabel PHP dan kutip tunggal di luar agar aman
	@echo '<?php $$db_host="localhost:$(DB_PORT)"; $$db_user="root"; $$db_pass="$(DB_ROOT_PASS)"; $$db_name="jbsakad"; ?>' > $(CONFIG_DB_FILE)
	@echo "File konfigurasi database $(CONFIG_DB_FILE) sukses dibuat."

	# Membuat config application
	# Pastikan $(DOMAIN) sudah terdefinisi di bagian atas Makefile atau .env
	@echo '<?php $$G_START_YEAR="2026"; $$G_SERVER_ADDR="$(DOMAIN)"; $$G_OS="lin"; $$G_LOKASI="Jakarta"; ?>' > $(CONFIG_APP_FILE)
	@echo "File konfigurasi app $(CONFIG_APP_FILE) sukses dibuat."

	# Membuat config sekolah
	@echo '<?php $$G_LOGO_DEPAN_KIRI="logo1.png"; $$G_LOGO_DEPAN_KANAN="logo2.png"; $$G_JUDUL_DEPAN_1="$(SEKOLAH)"; $$G_JUDUL_DEPAN_2="$(YAYASAN)"; $$G_JUDUL_DEPAN_3="$(ALAMAT)"; ?>' > $(CONFIG_SCH_FILE)
	@echo "  [OK] School config: $(CONFIG_SCH_FILE)"

	# Membuat config sharing
	@echo '<?php $$FILESHARE_UPLOAD_DIR="$(APP_DIR)/filesharing"; $$FILESHARE_ADDR="$(DOMAINHTTPS)"; ?>' > $(CONFIG_SHARE_FILE)
	@echo "  [OK] Fail filesharing dicipta."

# Target utama untuk instalasi
install: copy-app set-permissions config setup-database
	@echo "Instalasi JIBAS selesai."
	@echo "Pastikan Nginx dan PHP-FPM di host Anda sudah dikonfigurasi dengan benar."
	@echo "Akses aplikasi melalui browser Anda."

.PHONY: all clean download-extract copy-app set-permissions composer-install config setup-database install 
