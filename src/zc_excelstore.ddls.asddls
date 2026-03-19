@EndUserText.label: 'Excel Store Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true // Cho phép đọc Annotation từ file MDE

@UI: {
  headerInfo: {
    typeName: 'Kết quả xuất file',
    typeNamePlural: 'Kết quả xuất file',
    title: { type: #STANDARD, value: 'filename' }
  }
}


define root view entity ZC_ExcelStore
  as projection on ZI_ExcelStore
{
    key file_id,
    attachment,
    @UI.hidden: true
    mimetype,
    @UI.identification: [{ position: 10, label: 'Tên file' }]
    filename,
    
    @UI.identification: [{ 
        position: 20, 
        type: #WITH_URL,     -- Quan trọng: Định nghĩa đây là Hyperlink
        url: 'DownloadUrl',  -- Trỏ vào trường chứa text URL
        label: 'Tải xuống tại đây' 
    }]
    DownloadUrl
}
