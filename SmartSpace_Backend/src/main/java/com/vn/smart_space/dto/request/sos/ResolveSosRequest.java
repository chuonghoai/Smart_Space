package com.vn.smart_space.dto.request.sos;

import com.fasterxml.jackson.annotation.JsonProperty;

import jakarta.validation.constraints.Size;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

/** Admin kết thúc SOS: đã hỗ trợ xong, hoặc báo động nhầm. */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ResolveSosRequest {

    @JsonProperty("false_alarm")
    boolean falseAlarm;

    @Size(max = 500, message = "sos.note.too_long")
    String note;
}
