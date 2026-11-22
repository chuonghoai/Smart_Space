package com.vn.smart_space.model;

import java.util.LinkedHashSet;
import java.util.Set;

import com.vn.smart_space.consts.EReportSeverity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinTable;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.experimental.FieldDefaults;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Entity
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
@Table(name = "report_categories")
public class ReportCategory extends AbstractEntity {

    @Column(name = "code", nullable = false, unique = true, length = 50)
    String code;

    @Column(name = "name_vi", nullable = false, length = 120)
    String nameVi;

    @Column(name = "name_en", nullable = false, length = 120)
    String nameEn;

    @Column(name = "description", columnDefinition = "TEXT")
    String description;

    @Column(name = "icon_key", length = 50)
    String iconKey;

    @Enumerated(EnumType.STRING)
    @Column(name = "default_severity", nullable = false, length = 20)
    @Builder.Default
    EReportSeverity defaultSeverity = EReportSeverity.low;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    Boolean isActive = true;

    @Column(name = "display_order", nullable = false)
    @Builder.Default
    Integer displayOrder = 0;

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
            name = "report_category_positions",
            joinColumns = @JoinColumn(name = "category_id"),
            inverseJoinColumns = @JoinColumn(name = "position_id"))
    @Builder.Default
    Set<Position> positions = new LinkedHashSet<>();

}
