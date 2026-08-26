// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Localized strings for WebBar, the menu bar web browser and AI hub.
struct WebBarFeatureStrings {
    let pageTitle: String
    let hubDescription: String
    let panelCaption: String
    let openButton: String
    let shortcutLabel: String
    let showOnMenuBar: String
    let pinLabel: String
    let unpinLabel: String
    let opacityLabel: String
    let viewportLabel: String
    let newTab: String
    let closeTab: String
    let pasteLinkTitle: String
    let pasteLinkButton: String
    let quickAppsTitle: String
    let quickAppsCategoryAI: String
    let quickAppsCategoryTools: String
    let quickAppsCategorySocial: String
    let searchPlaceholder: String
    let autoPauseToggle: String
    let autoPauseCaption: String
    let adBlockToggle: String
    let adBlockCaption: String
    let closeOnClickOutside: String
    let reload: String
    let back: String
    let forward: String
    let zoomIn: String
    let zoomOut: String
    let zoomReset: String
    let notificationSectionTitle: String
    let experienceSectionTitle: String
    let notificationsToggle: String
    let notificationBadgesToggle: String
    let notificationSoundToggle: String
}

extension FeatureStrings {
    static func webBar(_ language: AppLanguage) -> WebBarFeatureStrings {
        switch language {
        case .enUS: return .enUS
        case .ptBR: return .ptBR
        case .tr: return .tr
        case .ru: return .ru
        case .es: return .es
        case .de: return .de
        case .it: return .it
        case .fr: return .fr
        case .zhHans: return .zhHans
        case .zhTW: return .zhTW
        case .zhHK: return .zhHK
        case .ja: return .ja
        case .ko: return .ko
        case .vi: return .vi
        }
    }
}

extension WebBarFeatureStrings {
    static let enUS = WebBarFeatureStrings(
        pageTitle: "WebBar",
        hubDescription: "Floating browser & AI hub on your menu bar with multi-viewport support.",
        panelCaption: "Open web apps and AI assistants instantly from your menu bar.",
        openButton: "Open WebBar",
        shortcutLabel: "Global Shortcut",
        showOnMenuBar: "Show in Menu Bar",
        pinLabel: "Pin on top",
        unpinLabel: "Unpin window",
        opacityLabel: "Window Opacity",
        viewportLabel: "Viewport Mode",
        newTab: "New Tab",
        closeTab: "Close Tab",
        pasteLinkTitle: "Open Website",
        pasteLinkButton: "Paste Link",
        quickAppsTitle: "Quick Web Apps & AI",
        quickAppsCategoryAI: "AI Assistants",
        quickAppsCategoryTools: "Productivity & Tools",
        quickAppsCategorySocial: "Social & Media",
        searchPlaceholder: "Enter or paste website URL...",
        autoPauseToggle: "Smart Auto-Pause Media",
        autoPauseCaption: "Automatically pauses videos and audio when the WebBar is hidden.",
        adBlockToggle: "Ad & Tracker Shield",
        adBlockCaption: "Block intrusive popup scripts and ad trackers.",
        closeOnClickOutside: "Close when clicking outside",
        reload: "Reload",
        back: "Back",
        forward: "Forward",
        zoomIn: "Zoom In",
        zoomOut: "Zoom Out",
        zoomReset: "Actual Size",
        notificationSectionTitle: "Notifications & Badges",
        experienceSectionTitle: "Experience & Protection",
        notificationsToggle: "Enable Web Notifications",
        notificationBadgesToggle: "Show Unread Badges on Menu Bar",
        notificationSoundToggle: "Play Sound for Notifications"
    )

    static let ptBR = WebBarFeatureStrings(
        pageTitle: "WebBar",
        hubDescription: "Navegador flutuante e hub de IA na barra de menus com suporte a múltiplas telas.",
        panelCaption: "Abra aplicativos da web e assistentes de IA instantaneamente na barra de menus.",
        openButton: "Abrir WebBar",
        shortcutLabel: "Atalho global",
        showOnMenuBar: "Mostrar na barra de menus",
        pinLabel: "Fixar no topo",
        unpinLabel: "Desafixar janela",
        opacityLabel: "Opacidade da janela",
        viewportLabel: "Modo de visualização",
        newTab: "Nova aba",
        closeTab: "Fechar aba",
        pasteLinkTitle: "Abrir Website",
        pasteLinkButton: "Colar Link",
        quickAppsTitle: "Aplicativos Web e IA",
        quickAppsCategoryAI: "Assistentes de IA",
        quickAppsCategoryTools: "Produtividade e Ferramentas",
        quickAppsCategorySocial: "Redes Sociais e Mídia",
        searchPlaceholder: "Digite ou cole a URL...",
        autoPauseToggle: "Pausar mídia automaticamente",
        autoPauseCaption: "Pausa vídeos e áudio automaticamente quando a WebBar é ocultada.",
        adBlockToggle: "Bloqueador de Anúncios",
        adBlockCaption: "Bloqueia scripts invasivos e rastreadores de anúncios.",
        closeOnClickOutside: "Fechar ao clicar fora",
        reload: "Recarregar",
        back: "Voltar",
        forward: "Avançar",
        zoomIn: "Aumentar zoom",
        zoomOut: "Diminuir zoom",
        zoomReset: "Tamanho real",
        notificationSectionTitle: "Notificações e emblemas",
        experienceSectionTitle: "Experiência e proteção",
        notificationsToggle: "Ativar notificações da Web",
        notificationBadgesToggle: "Mostrar emblemas de não lidos na barra de menus",
        notificationSoundToggle: "Reproduzir som para notificações"
    )

    static let tr = WebBarFeatureStrings(
        pageTitle: "WebBar",
        hubDescription: "Çoklu görünüm destekli menü çubuğu kayan web tarayıcısı ve yapay zeka merkezi.",
        panelCaption: "Web uygulamalarını ve yapay zeka asistanlarını menü çubuğunuzdan anında açın.",
        openButton: "WebBar'ı Aç",
        shortcutLabel: "Genel Kısayol",
        showOnMenuBar: "Menü Çubuğunda Göster",
        pinLabel: "Üstte sabitle",
        unpinLabel: "Sabitlemeyi kaldır",
        opacityLabel: "Pencere Saydamlığı",
        viewportLabel: "Görünüm Modu",
        newTab: "Yeni Sekme",
        closeTab: "Sekmeyi Kapat",
        pasteLinkTitle: "Web Sitesi Aç",
        pasteLinkButton: "Bağlantıyı Yapıştır",
        quickAppsTitle: "Hızlı Web Uygulamaları ve Yapay Zeka",
        quickAppsCategoryAI: "Yapay Zeka Asistanları",
        quickAppsCategoryTools: "Verimlilik ve Araçlar",
        quickAppsCategorySocial: "Sosyal ve Medya",
        searchPlaceholder: "URL girin veya yapıştırın...",
        autoPauseToggle: "Medyayı Otomatik Duraklat",
        autoPauseCaption: "WebBar gizlendiğinde videoları ve sesleri otomatik olarak duraklatır.",
        adBlockToggle: "Reklam ve Takipçi Kalkanı",
        adBlockCaption: "Açılır pencereleri ve reklam izleyicilerini engeller.",
        closeOnClickOutside: "Dışarı tıklandığında kapat",
        reload: "Yenile",
        back: "Geri",
        forward: "İleri",
        zoomIn: "Yakınlaştır",
        zoomOut: "Uzaklaştır",
        zoomReset: "Gerçek Boyut",
        notificationSectionTitle: "Bildirimler ve rozetler",
        experienceSectionTitle: "Deneyim ve koruma",
        notificationsToggle: "Web Bildirimlerini Etkinleştir",
        notificationBadgesToggle: "Menü Çubuğunda Okunmamış Rozetlerini Göster",
        notificationSoundToggle: "Bildirimler için Ses Çal"
    )

    static let ru = WebBarFeatureStrings(
        pageTitle: "WebBar",
        hubDescription: "Плавающий браузер и ИИ-хаб в строке меню с поддержкой различных разрешений.",
        panelCaption: "Мгновенно открывайте веб-приложения и ИИ-ассистентов из строки меню.",
        openButton: "Открыть WebBar",
        shortcutLabel: "Глобальное сочетание",
        showOnMenuBar: "Показывать в строке меню",
        pinLabel: "Закрепить поверх всех",
        unpinLabel: "Открепить окно",
        opacityLabel: "Прозрачность окна",
        viewportLabel: "Режим экрана",
        newTab: "Новая вкладка",
        closeTab: "Закрыть вкладку",
        pasteLinkTitle: "Открыть сайт",
        pasteLinkButton: "Вставить ссылку",
        quickAppsTitle: "Веб-приложения и ИИ",
        quickAppsCategoryAI: "ИИ-ассистенты",
        quickAppsCategoryTools: "Продуктивность и инструменты",
        quickAppsCategorySocial: "Соцсети и медиа",
        searchPlaceholder: "Введите или вставьте URL...",
        autoPauseToggle: "Автопауза медиа",
        autoPauseCaption: "Автоматически ставит видео и аудио на паузу при скрытии WebBar.",
        adBlockToggle: "Блокировка рекламы и трекеров",
        adBlockCaption: "Блокирует всплывающие окна и рекламные трекеры.",
        closeOnClickOutside: "Закрывать при клике снаружи",
        reload: "Перезагрузить",
        back: "Назад",
        forward: "Вперед",
        zoomIn: "Увеличить",
        zoomOut: "Уменьшить",
        zoomReset: "Реальный размер",
        notificationSectionTitle: "Уведомления и значки",
        experienceSectionTitle: "Удобство и защита",
        notificationsToggle: "Включить веб-уведомления",
        notificationBadgesToggle: "Показывать значки непрочитанных в строке меню",
        notificationSoundToggle: "Воспроизводить звук для уведомлений"
    )

    static let es = WebBarFeatureStrings(
        pageTitle: "WebBar",
        hubDescription: "Navegador flotante y centro de IA en la barra de menús con soporte para múltiples vistas.",
        panelCaption: "Abra aplicaciones web y asistentes de IA al instante desde su barra de menús.",
        openButton: "Abrir WebBar",
        shortcutLabel: "Acceso directo global",
        showOnMenuBar: "Mostrar en la barra de menús",
        pinLabel: "Fijar en primer plano",
        unpinLabel: "Desfijar ventana",
        opacityLabel: "Opacidad de la ventana",
        viewportLabel: "Modo de visualización",
        newTab: "Nueva pestaña",
        closeTab: "Cerrar pestaña",
        pasteLinkTitle: "Abrir Sitio Web",
        pasteLinkButton: "Pegar Enlace",
        quickAppsTitle: "Apps Web Rápidas e IA",
        quickAppsCategoryAI: "Asistentes de IA",
        quickAppsCategoryTools: "Productividad y Herramientas",
        quickAppsCategorySocial: "Social y Medios",
        searchPlaceholder: "Introduzca o pegue una URL...",
        autoPauseToggle: "Pausa automática de medios",
        autoPauseCaption: "Pausa automáticamente el contenido multimedia al ocultar WebBar.",
        adBlockToggle: "Bloqueador de anuncios",
        adBlockCaption: "Bloquea ventanas emergentes y rastreadores de publicidad.",
        closeOnClickOutside: "Cerrar al hacer clic fuera",
        reload: "Recargar",
        back: "Atrás",
        forward: "Adelante",
        zoomIn: "Acercar",
        zoomOut: "Alejar",
        zoomReset: "Tamaño real",
        notificationSectionTitle: "Notificaciones e insignias",
        experienceSectionTitle: "Experiencia y protección",
        notificationsToggle: "Activar notificaciones web",
        notificationBadgesToggle: "Mostrar distintivos de no leídos en la barra de menús",
        notificationSoundToggle: "Reproducir sonido para notificaciones"
    )

    static let de = WebBarFeatureStrings(
        pageTitle: "WebBar",
        hubDescription: "Schwebender Browser & KI-Hub in Ihrer Menüleiste mit Multi-Viewport-Unterstützung.",
        panelCaption: "Web-Apps und KI-Assistenten direkt aus der Menüleiste öffnen.",
        openButton: "WebBar öffnen",
        shortcutLabel: "Globaler Kurzbefehl",
        showOnMenuBar: "In der Menüleiste anzeigen",
        pinLabel: "Oben anheften",
        unpinLabel: "Fenster lösen",
        opacityLabel: "Fenster-Deckkraft",
        viewportLabel: "Viewport-Modus",
        newTab: "Neuer Tab",
        closeTab: "Tab schließen",
        pasteLinkTitle: "Website öffnen",
        pasteLinkButton: "Link einfügen",
        quickAppsTitle: "Schnelle Web-Apps & KI",
        quickAppsCategoryAI: "KI-Assistenten",
        quickAppsCategoryTools: "Produktivität & Tools",
        quickAppsCategorySocial: "Soziales & Medien",
        searchPlaceholder: "URL eingeben oder einfügen...",
        autoPauseToggle: "Medien automatisch anhalten",
        autoPauseCaption: "Pausiert Videos und Audio automatisch, wenn WebBar ausgeblendet wird.",
        adBlockToggle: "Werbe- & Tracker-Schutz",
        adBlockCaption: "Blockiert störende Popups und Tracking-Skripte.",
        closeOnClickOutside: "Beim Klicken außerhalb schließen",
        reload: "Neu laden",
        back: "Zurück",
        forward: "Vorwärts",
        zoomIn: "Vergrößern",
        zoomOut: "Verkleinern",
        zoomReset: "Originalgröße",
        notificationSectionTitle: "Mitteilungen & Kennzeichen",
        experienceSectionTitle: "Nutzung & Schutz",
        notificationsToggle: "Web-Benachrichtigungen aktivieren",
        notificationBadgesToggle: "Ungelesene Badges in der Menüleiste anzeigen",
        notificationSoundToggle: "Ton für Benachrichtigungen abspielen"
    )

    static let it = WebBarFeatureStrings(
        pageTitle: "WebBar",
        hubDescription: "Browser mobile e hub IA nella barra dei menu con supporto multi-viewport.",
        panelCaption: "Apri app web e assistenti IA all'istante dalla barra dei menu.",
        openButton: "Apri WebBar",
        shortcutLabel: "Scorciatoia globale",
        showOnMenuBar: "Mostra nella barra dei menu",
        pinLabel: "Blocca in primo piano",
        unpinLabel: "Sblocca finestra",
        opacityLabel: "Opacità finestra",
        viewportLabel: "Modalità viewport",
        newTab: "Nuova scheda",
        closeTab: "Chiudi scheda",
        pasteLinkTitle: "Apri Sito Web",
        pasteLinkButton: "Incolla Link",
        quickAppsTitle: "App Web Rapide e IA",
        quickAppsCategoryAI: "Assistenti IA",
        quickAppsCategoryTools: "Produttività e Strumenti",
        quickAppsCategorySocial: "Social e Media",
        searchPlaceholder: "Inserisci o incolla l'URL...",
        autoPauseToggle: "Pausa automatica dei media",
        autoPauseCaption: "Mette in pausa automaticamente video e audio quando la WebBar viene nascosta.",
        adBlockToggle: "Blocco annunci e tracker",
        adBlockCaption: "Blocca popup invasivi e tracker pubblicitari.",
        closeOnClickOutside: "Chiudi cliccando all'esterno",
        reload: "Ricarica",
        back: "Indietro",
        forward: "Avanti",
        zoomIn: "Ingrandisci",
        zoomOut: "Rimpicciolisci",
        zoomReset: "Dimensioni reali",
        notificationSectionTitle: "Notifiche e badge",
        experienceSectionTitle: "Esperienza e protezione",
        notificationsToggle: "Abilita notifiche web",
        notificationBadgesToggle: "Mostra badge non letti nella barra dei menu",
        notificationSoundToggle: "Riproduci suono per le notifiche"
    )

    static let fr = WebBarFeatureStrings(
        pageTitle: "WebBar",
        hubDescription: "Navigateur flottant et hub d'IA dans la barre des menus avec support multi-écrans.",
        panelCaption: "Ouvrez instantanément vos applications Web et assistants IA depuis la barre des menus.",
        openButton: "Ouvrir WebBar",
        shortcutLabel: "Raccourci global",
        showOnMenuBar: "Afficher dans la barre des menus",
        pinLabel: "Épingler au premier plan",
        unpinLabel: "Détacher la fenêtre",
        opacityLabel: "Opacité de la fenêtre",
        viewportLabel: "Mode d'affichage",
        newTab: "Nouvel onglet",
        closeTab: "Fermer l'onglet",
        pasteLinkTitle: "Ouvrir le site Web",
        pasteLinkButton: "Coller le lien",
        quickAppsTitle: "Applications Web et IA",
        quickAppsCategoryAI: "Assistants IA",
        quickAppsCategoryTools: "Productivité et Outils",
        quickAppsCategorySocial: "Réseaux sociaux et Médias",
        searchPlaceholder: "Saisir ou coller une URL...",
        autoPauseToggle: "Pause automatique des médias",
        autoPauseCaption: "Met automatiquement en pause les vidéos et l'audio lorsque la WebBar est masquée.",
        adBlockToggle: "Bloqueur de publicités et traqueurs",
        adBlockCaption: "Bloque les fenêtres publicitaires et les traceurs.",
        closeOnClickOutside: "Fermer en cliquant à l'extérieur",
        reload: "Recharger",
        back: "Retour",
        forward: "Avancer",
        zoomIn: "Zoom avant",
        zoomOut: "Zoom arrière",
        zoomReset: "Taille réelle",
        notificationSectionTitle: "Notifications et badges",
        experienceSectionTitle: "Expérience et protection",
        notificationsToggle: "Activer les notifications Web",
        notificationBadgesToggle: "Afficher les badges non lus dans la barre des menus",
        notificationSoundToggle: "Émettre un son pour les notifications"
    )

    static let zhHans = WebBarFeatureStrings(
        pageTitle: "WebBar",
        hubDescription: "菜单栏悬浮网页浏览器与 AI 聚合中心，支持多种视口尺寸。",
        panelCaption: "从菜单栏即刻唤出网页应用与 AI 助手。",
        openButton: "打开 WebBar",
        shortcutLabel: "全局快捷键",
        showOnMenuBar: "在菜单栏显示",
        pinLabel: "置顶窗口",
        unpinLabel: "取消置顶",
        opacityLabel: "窗口不透明度",
        viewportLabel: "视口模式",
        newTab: "新建标签页",
        closeTab: "关闭标签页",
        pasteLinkTitle: "打开网址",
        pasteLinkButton: "粘贴链接",
        quickAppsTitle: "快速网页应用与 AI",
        quickAppsCategoryAI: "AI 助手",
        quickAppsCategoryTools: "效率与工具",
        quickAppsCategorySocial: "社交与媒体",
        searchPlaceholder: "输入或粘贴网址...",
        autoPauseToggle: "智能媒体自动暂停",
        autoPauseCaption: "在 WebBar 隐藏时自动暂停正在播放的视频与音频。",
        adBlockToggle: "广告与跟踪拦截",
        adBlockCaption: "拦截干扰性弹窗与广告跟踪脚本。",
        closeOnClickOutside: "点击外部时关闭",
        reload: "重新加载",
        back: "后退",
        forward: "前进",
        zoomIn: "放大",
        zoomOut: "缩小",
        zoomReset: "实际大小",
        notificationSectionTitle: "通知与标记",
        experienceSectionTitle: "体验与保护",
        notificationsToggle: "启用网页通知",
        notificationBadgesToggle: "在菜单栏显示未读红点标记",
        notificationSoundToggle: "播放通知声音"
    )

    static let zhTW = WebBarFeatureStrings(
        pageTitle: "WebBar",
        hubDescription: "選單列懸浮網頁瀏覽器與 AI 聚合中心，支援多種視窗尺寸。",
        panelCaption: "從選單列即刻開啟網頁應用與 AI 助手。",
        openButton: "開啟 WebBar",
        shortcutLabel: "全域快速鍵",
        showOnMenuBar: "在選單列顯示",
        pinLabel: "置頂視窗",
        unpinLabel: "取消置頂",
        opacityLabel: "視窗不透明度",
        viewportLabel: "視口模式",
        newTab: "新增分頁",
        closeTab: "關閉分頁",
        pasteLinkTitle: "開啟網址",
        pasteLinkButton: "貼上連結",
        quickAppsTitle: "快速網頁應用與 AI",
        quickAppsCategoryAI: "AI 助手",
        quickAppsCategoryTools: "生產力與工具",
        quickAppsCategorySocial: "社群與媒體",
        searchPlaceholder: "輸入或貼上網址...",
        autoPauseToggle: "智慧媒體自動暫停",
        autoPauseCaption: "在 WebBar 隱藏時自動暫停正在播放的影片與音訊。",
        adBlockToggle: "廣告與追蹤攔截",
        adBlockCaption: "攔截彈出視窗與廣告追蹤指令碼。",
        closeOnClickOutside: "點擊外部時關閉",
        reload: "重新載入",
        back: "返回",
        forward: "前進",
        zoomIn: "放大",
        zoomOut: "縮小",
        zoomReset: "實際大小",
        notificationSectionTitle: "通知與標記",
        experienceSectionTitle: "體驗與保護",
        notificationsToggle: "啟用網頁通知",
        notificationBadgesToggle: "在選單列顯示未讀紅點標記",
        notificationSoundToggle: "播放通知聲音"
    )

    static let zhHK = WebBarFeatureStrings(
        pageTitle: "WebBar",
        hubDescription: "選單列懸浮網頁瀏覽器與 AI 聚合中心，支援多種視窗尺寸。",
        panelCaption: "從選單列即刻開啟網頁應用與 AI 助手。",
        openButton: "開啟 WebBar",
        shortcutLabel: "全域快速鍵",
        showOnMenuBar: "在選單列顯示",
        pinLabel: "置頂視窗",
        unpinLabel: "取消置頂",
        opacityLabel: "視窗不透明度",
        viewportLabel: "視口模式",
        newTab: "新增分頁",
        closeTab: "關閉分頁",
        pasteLinkTitle: "開啟網址",
        pasteLinkButton: "貼上連結",
        quickAppsTitle: "快速網頁應用與 AI",
        quickAppsCategoryAI: "AI 助手",
        quickAppsCategoryTools: "生產力與工具",
        quickAppsCategorySocial: "社群與媒體",
        searchPlaceholder: "輸入或貼上網址...",
        autoPauseToggle: "智慧媒體自動暫停",
        autoPauseCaption: "在 WebBar 隱藏時自動暫停正在播放的影片與音訊。",
        adBlockToggle: "廣告與追蹤攔截",
        adBlockCaption: "攔截彈出視窗與廣告追蹤指令碼。",
        closeOnClickOutside: "點擊外部時關閉",
        reload: "重新載入",
        back: "返回",
        forward: "前進",
        zoomIn: "放大",
        zoomOut: "縮小",
        zoomReset: "實際大小",
        notificationSectionTitle: "通知與標記",
        experienceSectionTitle: "體驗與保護",
        notificationsToggle: "啟用網頁通知",
        notificationBadgesToggle: "在選單列顯示未讀紅點標記",
        notificationSoundToggle: "播放通知聲音"
    )

    static let ja = WebBarFeatureStrings(
        pageTitle: "WebBar",
        hubDescription: "メニューバーのフローティングWebブラウザ＆AIハブ（マルチビューポート対応）。",
        panelCaption: "メニューバーからWebアプリやAIアシスタントをすばやく起動できます。",
        openButton: "WebBarを開く",
        shortcutLabel: "グローバルショートカット",
        showOnMenuBar: "メニューバーに表示",
        pinLabel: "最前面に固定",
        unpinLabel: "固定を解除",
        opacityLabel: "ウィンドウの不透明度",
        viewportLabel: "ビューポートモード",
        newTab: "新規タブ",
        closeTab: "タブを閉じる",
        pasteLinkTitle: "ウェブサイトを開く",
        pasteLinkButton: "リンクを貼り付け",
        quickAppsTitle: "クイックWebアプリ＆AI",
        quickAppsCategoryAI: "AIアシスタント",
        quickAppsCategoryTools: "仕事・ツール",
        quickAppsCategorySocial: "SNS・メディア",
        searchPlaceholder: "URLを入力または貼り付け...",
        autoPauseToggle: "メディアの自動一時停止",
        autoPauseCaption: "WebBarが非表示になると動画や音声を自動的に一時停止します。",
        adBlockToggle: "広告＆トラッカーブロック",
        adBlockCaption: "邪魔なポップアップやトラッキングスクリプトをブロックします。",
        closeOnClickOutside: "外側をクリックして閉じる",
        reload: "再読み込み",
        back: "戻る",
        forward: "進む",
        zoomIn: "拡大",
        zoomOut: "縮小",
        zoomReset: "実際のサイズ",
        notificationSectionTitle: "通知とバッジ",
        experienceSectionTitle: "体験と保護",
        notificationsToggle: "Web通知を有効にする",
        notificationBadgesToggle: "メニューバーに未読バッジを表示",
        notificationSoundToggle: "通知音を鳴らす"
    )

    static let ko = WebBarFeatureStrings(
        pageTitle: "WebBar",
        hubDescription: "메뉴 막대 플로팅 웹 브라우저 및 AI 허브.",
        panelCaption: "메뉴 막대에서 웹 앱과 AI 어시스턴트를 바로 실행하세요.",
        openButton: "WebBar 열기",
        shortcutLabel: "글로벌 단축키",
        showOnMenuBar: "메뉴 막대에 표시",
        pinLabel: "상단 고정",
        unpinLabel: "고정 해제",
        opacityLabel: "창 불투명도",
        viewportLabel: "뷰포트 모드",
        newTab: "새 탭",
        closeTab: "탭 닫기",
        pasteLinkTitle: "웹사이트 열기",
        pasteLinkButton: "링크 붙여넣기",
        quickAppsTitle: "빠른 웹 앱 및 AI",
        quickAppsCategoryAI: "AI 어시스턴트",
        quickAppsCategoryTools: "생산성 및 도구",
        quickAppsCategorySocial: "소셜 및 미디어",
        searchPlaceholder: "URL 입력 또는 붙여넣기...",
        autoPauseToggle: "스마트 미디어 자동 일시정지",
        autoPauseCaption: "WebBar를 숨길 때 동영상 및 오디오를 자동으로 일시정지합니다.",
        adBlockToggle: "광고 및 트래커 차단",
        adBlockCaption: "방해되는 팝업 및 광고 추적기를 차단합니다.",
        closeOnClickOutside: "외부 클릭 시 닫기",
        reload: "새로고침",
        back: "뒤로",
        forward: "앞으로",
        zoomIn: "확대",
        zoomOut: "축소",
        zoomReset: "실제 크기",
        notificationSectionTitle: "알림 및 배지",
        experienceSectionTitle: "사용 경험 및 보호",
        notificationsToggle: "웹 알림 활성화",
        notificationBadgesToggle: "메뉴 막대에 읽지 않은 배지 표시",
        notificationSoundToggle: "알림 소리 재생"
    )

    static let vi = WebBarFeatureStrings(
        pageTitle: "WebBar",
        hubDescription: "Trình duyệt web và trung tâm trợ lý AI nổi trên thanh menu với hỗ trợ nhiều kích thước màn hình.",
        panelCaption: "Mở ứng dụng web và trợ lý AI tức thì ngay từ thanh menu của bạn.",
        openButton: "Mở WebBar",
        shortcutLabel: "Phím tắt toàn cục",
        showOnMenuBar: "Hiển thị trên thanh menu",
        pinLabel: "Ghim trên cùng",
        unpinLabel: "Bỏ ghim cửa sổ",
        opacityLabel: "Độ mờ cửa sổ",
        viewportLabel: "Chế độ hiển thị",
        newTab: "Tab mới",
        closeTab: "Đóng tab",
        pasteLinkTitle: "Dán Liên Kết Website",
        pasteLinkButton: "Dán Link",
        quickAppsTitle: "Ứng dụng Web & AI nhanh",
        quickAppsCategoryAI: "Trợ lý AI",
        quickAppsCategoryTools: "Công việc & Tiện ích",
        quickAppsCategorySocial: "Mạng xã hội & Media",
        searchPlaceholder: "Nhập hoặc dán link website...",
        autoPauseToggle: "Tự động dừng phát media thông minh",
        autoPauseCaption: "Tự động tạm dừng video và âm thanh khi đóng hoặc ẩn WebBar.",
        adBlockToggle: "Chặn quảng cáo & Trình theo dõi",
        adBlockCaption: "Chặn các cửa sổ quảng cáo bật lên và theo dõi người dùng.",
        closeOnClickOutside: "Đóng khi nhấp ra ngoài",
        reload: "Tải lại",
        back: "Quay lại",
        forward: "Tiến tới",
        zoomIn: "Phóng to",
        zoomOut: "Thu nhỏ",
        zoomReset: "Kích thước thực",
        notificationSectionTitle: "Thông báo & Huy hiệu",
        experienceSectionTitle: "Trải nghiệm & Bảo vệ",
        notificationsToggle: "Bật thông báo Web (HTML5 Notifications)",
        notificationBadgesToggle: "Hiện chấm đỏ tin nhắn chưa đọc trên Menu Bar",
        notificationSoundToggle: "Phát âm thanh khi có thông báo"
    )
}
