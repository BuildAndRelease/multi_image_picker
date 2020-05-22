package com.sangcomz.fishbun.bean;

import android.os.Parcel;
import android.os.Parcelable;

import androidx.annotation.NonNull;

public class Media implements Parcelable {

    private String bucketName = "";
    private String bucketId = "";
    private String originPath = "";
    private String originHeight = "";
    private String originWidth = "";
    private String originName = "";
    private String duration = "";
    private String thumbnailPath = "";
    private String thumbnailHeight = "";
    private String thumbnailWidth = "";
    private String thumbnailName = "";
    private String fileType = "";
    private String mimeType = "";
    private String identifier = "";

    public Media() {

    }

    public void setBucketId(String bucketId) {
        this.bucketId = bucketId;
    }

    public String getBucketId() {
        return bucketId;
    }

    public void setBucketName(String bucketName) {
        this.bucketName = bucketName;
    }

    public String getBucketName() {
        return bucketName;
    }

    public void setFileType(String fileType) {
        this.fileType = fileType;
    }

    public String getFileType() {
        return fileType;
    }

    public void setIdentifier(String identifier) {
        this.identifier = identifier;
    }

    public String getIdentifier() {
        return identifier;
    }

    public void setOriginHeight(String originHeight) {
        this.originHeight = originHeight;
    }

    public String getOriginHeight() {
        return originHeight;
    }

    public void setOriginName(String originName) {
        this.originName = originName;
    }

    public String getOriginName() {
        return originName;
    }

    public void setOriginPath(String originPath) {
        this.originPath = originPath;
    }

    public String getOriginPath() {
        return originPath;
    }

    public void setOriginWidth(String originWidth) {
        this.originWidth = originWidth;
    }

    public String getOriginWidth() {
        return originWidth;
    }

    public void setDuration(String duration) {
        this.duration = duration;
    }

    public String getDuration() {
        return duration;
    }

    public void setMimeType(String mimeType) {
        this.mimeType = mimeType;
    }

    public String getMimeType() {
        return mimeType;
    }

    public void setThumbnailHeight(String thumbnailHeight) {
        this.thumbnailHeight = thumbnailHeight;
    }

    public String getThumbnailHeight() {
        return thumbnailHeight;
    }

    public void setThumbnailName(String thumbnailName) {
        this.thumbnailName = thumbnailName;
    }

    public String getThumbnailName() {
        return thumbnailName;
    }

    public void setThumbnailPath(String thumbnailPath) {
        this.thumbnailPath = thumbnailPath;
    }

    public String getThumbnailPath() {
        return thumbnailPath;
    }

    public void setThumbnailWidth(String thumbnailWidth) {
        this.thumbnailWidth = thumbnailWidth;
    }

    public String getThumbnailWidth() {
        return thumbnailWidth;
    }

    protected Media(Parcel in) {
        this.bucketName = in.readString();
        this.bucketId = in.readString();
        this.originPath = in.readString();
        this.originHeight = in.readString();
        this.originWidth = in.readString();
        this.originName = in.readString();
        this.duration = in.readString();
        this.thumbnailPath = in.readString();
        this.thumbnailHeight = in.readString();
        this.thumbnailWidth = in.readString();
        this.thumbnailName = in.readString();
        this.fileType = in.readString();
        this.mimeType = in.readString();
        this.identifier = in.readString();
    }

    public static final Creator<Media> CREATOR = new Creator<Media>() {
        @Override
        public Media createFromParcel(Parcel in) {
            return new Media(in);
        }

        @Override
        public Media[] newArray(int size) {
            return new Media[size];
        }
    };

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel parcel, int i) {
        parcel.writeString(bucketName);
        parcel.writeString(bucketId);
        parcel.writeString(originPath);
        parcel.writeString(originHeight);
        parcel.writeString(originWidth);
        parcel.writeString(originName);
        parcel.writeString(duration);
        parcel.writeString(thumbnailPath);
        parcel.writeString(thumbnailHeight);
        parcel.writeString(thumbnailWidth);
        parcel.writeString(thumbnailName);
        parcel.writeString(fileType);
        parcel.writeString(mimeType);
        parcel.writeString(identifier);
    }

    @NonNull
    @Override
    public String toString() {
        return "bucketName:" + bucketName + " bucketId:" + bucketId + " originPath:" + originPath + " originHeight:" + originHeight +
        " originWidth:" + originWidth + " originName:" + originName + " duration:" + duration + " thumbnailPath:" + thumbnailPath +
        " thumbnailHeight:" + thumbnailHeight + " thumbnailWidth:" + thumbnailWidth + " thumbnailName:" + thumbnailName + " fileType:" + fileType +
        " mimeType:" + mimeType + " identifier:" + identifier;
    }
}
