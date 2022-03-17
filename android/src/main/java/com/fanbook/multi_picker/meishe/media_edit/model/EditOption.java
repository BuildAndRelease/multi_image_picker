package com.fanbook.multi_picker.meishe.media_edit.model;

public class EditOption {
    private String title;
    private String icon;

    public EditOption(String title, String icon) {
        this.title = title;
        this.icon = icon;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getIcon() {
        return icon;
    }

    public void setIcon(String icon) {
        this.icon = icon;
    }
}
